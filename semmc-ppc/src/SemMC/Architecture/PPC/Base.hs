{-# LANGUAGE BinaryLiterals #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImplicitParams #-}
-- | The definitions of the base and manual sets of formulas
--
-- This is the set of definitions shared between PPC32 and PPC64
--
-- base and manual are specified separately so that we can store them in
-- different places (manual definitions are not included in the base set, since
-- we don't want to or cannot learn from them).
module SemMC.Architecture.PPC.Base (
  BitSize(..),
  base,
  pseudo,
  manual
  ) where

import Prelude hiding ( concat )
import SemMC.DSL
import SemMC.Architecture.PPC.Base.Core
import SemMC.Architecture.PPC.Base.Arithmetic
import SemMC.Architecture.PPC.Base.Bitwise
import SemMC.Architecture.PPC.Base.Branch
import SemMC.Architecture.PPC.Base.Compare
import SemMC.Architecture.PPC.Base.FP
import SemMC.Architecture.PPC.Base.Memory
import SemMC.Architecture.PPC.Base.Special
import SemMC.Architecture.PPC.Base.Sync
import SemMC.Architecture.PPC.Base.Vector
import SemMC.Architecture.PPC.Base.VSX

-- Defs

base :: BitSize -> Package
base bitSize = runSem $ do
  let ?bitSize = bitSize
  baseArithmetic
  baseBitwise
  baseCompare
  baseSpecial
  baseSync
  baseVector
  baseVSX

pseudo :: BitSize -> Package
pseudo bitSize = runSem $ do
  let ?bitSize = bitSize
  defineOpcode "Move" $ do
    target <- param "target" gprc naturalBV
    source <- param "source" gprc_nor0 naturalBV
    input source
    defLoc target (Loc source)
  defineOpcode "ExtractByteGPR" $ do
    target <- param "target" gprc naturalBV
    source <- param "source" gprc naturalBV
    n <- if bitSize == Size32 then param "n" u2imm (EBV 2) else param "n" u4imm (EBV 4)
    input source
    input n
    let shiftAmount = bvshl (zext (Loc n)) (naturalLitBV 0x3)
    let shiftedInput = bvlshr (Loc source) shiftAmount
    let bits = lowBits 8 shiftedInput
    let padding = LitBV (bitSizeValue bitSize - 8) 0x0
    defLoc target (concat padding bits)
  defineOpcode "SetSignedCR0" $ do
    comment "SetCR0"
    comment "This pseudo-opcode sets the value of CR0 based on a comparison"
    comment "of the value in the input register against zero, as in CMPDI or CMPWI"
    rA <- param "rA" gprc naturalBV
    input cr
    input xer
    input rA
    let ximm = naturalLitBV 0x0
    let newCR = cmpImm bvslt bvsgt (LitBV 3 0x0) ximm (Loc rA)
    defLoc cr newCR
  return ()

manual :: BitSize -> Package
manual bitSize = runSem $ do
  let ?bitSize = bitSize
  manualBranch
  manualMemory
  floatingPoint
  floatingPointLoads
  floatingPointStores
  floatingPointCompare
  defineOpcodeWithIP "MTLR" $ do
    rA <- param "rA" gprc naturalBV
    input rA
    defLoc lnk (Loc rA)
  defineOpcodeWithIP "MR" $ do
    rT <- param "rT" gprc naturalBV
    rA <- param "rA" gprc naturalBV
    input rA
    defLoc rT (Loc rA)
  defineOpcodeWithIP "MFLR" $ do
    rA <- param "rA" gprc naturalBV
    input lnk
    defLoc rA (Loc lnk)
  defineOpcodeWithIP "MTCTR" $ do
    rA <- param "rA" gprc naturalBV
    input rA
    defLoc ctr (Loc rA)
  defineOpcodeWithIP "MFCTR" $ do
    rA <- param "rA" gprc naturalBV
    input ctr
    defLoc rA (Loc ctr)
  defineOpcodeWithIP "LI" $ do
    rA <- param "rA" gprc naturalBV
    imm <- param "imm" s16imm (EBV 16)
    input imm
    defLoc rA (sext (Loc imm))
  defineOpcodeWithIP "LIS" $ do
    rT <- param "rT" gprc naturalBV
    imm <- param "imm" s17imm (EBV 16)
    input imm
    defLoc rT (sext (concat (Loc imm) (LitBV 16 0x0)))
  defineOpcodeWithIP "NOP" $ return ()
  return ()


{- Note [PPC Condition Register (CR)]

The CR is 32 bits, which are usually addressed as eight 4-bit fields (CR0-CR7).

 - CR0 is set as the implicit result of many fixed point operations
 - CR1 is set as the implicit result of many floating point operations
 - CR fields can be set as the result of various compare instructions

Individual field bits are assigned based on comparison of the result of an
operation (R) to a constant (C) (either via the compare instructions *or*
against 0 when CR0 is implicitly set) as follows:

| Bit | Name | Description               |
|-----+------+---------------------------|
|   0 | LT   | True if R < C             |
|   1 | GT   | True if R > C             |
|   2 | EQ   | True if R = C             |
|   3 | SO   | Summary Overflow from XER |

If we write out the semantics for the basic compare instructions, we should be
in pretty good shape.  We can then write a specialized compare instruction as an
intrinsic with its constant fixed to zero.  That would let us learn most of the
dotted variants.

-}

