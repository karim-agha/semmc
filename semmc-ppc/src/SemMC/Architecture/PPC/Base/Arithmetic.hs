{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImplicitParams #-}
module SemMC.Architecture.PPC.Base.Arithmetic (
  baseArithmetic
  ) where

import Prelude hiding ( concat )
import Control.Monad ( when )

import qualified Dismantle.PPC as P

import SemMC.DSL
import SemMC.Architecture.PPC.Base.Core

baseArithmetic :: (?bitSize :: BitSize) => SemM 'Top ()
baseArithmetic = do
  definePPCOpcode P.ADD4 xoform3c $ \rT rB rA -> do
    comment "ADD (XO-form, RC=0)"
    let val = bvadd (Loc rA) (Loc rB)
    defLoc rT val
    definePPCOpcodeRC P.ADD4o val $ do
      comment "ADD. (XO-form, RC=1)"
  definePPCOpcode P.SUBF xoform3c $ \rT rB rA -> do
    comment "SUBF (XO-form, RC=0)"
    let val = bvsub (Loc rB) (Loc rA)
    defLoc rT val
    definePPCOpcodeRC P.SUBFo val $ do
      comment "SUBF. (XO-form, RC=1)"
  defineOpcodeWithIP "NEG" $ do
    comment "Negate (XO-form, RC=0)"
    rT <- param "rT" gprc naturalBV
    rA <- param "rA" gprc naturalBV
    input rA
    let res = bvadd (bvnot (Loc rA)) (naturalLitBV 0x1)
    defLoc rT res
    defineRCVariant "NEGo" res $ do
      comment "Negate (XO-form, RC=1)"
  defineOpcodeWithIP "MULLI" $ do
    comment "Multiply Low Immediate (D-form)"
    (rT, rA, si) <- dformr0
    let prod = bvmul (Loc rA) (sext (Loc si))
    defLoc rT prod
  definePPCOpcode P.MULLW xoform3c $ \rT rB rA -> do
    comment "Multiply Low Word (XO-form, RC=0)"
    let lhs = sext' 64 (lowBits 32 (Loc rA))
    let rhs = sext' 64 (lowBits 32 (Loc rB))
    let prod = bvmul lhs rhs
    let res = zext (lowBits64 32 prod)
    defLoc rT res
    definePPCOpcodeRC P.MULLWo res $ do
      comment "Multiply Low Word (XO-form, RC=1)"
  definePPCOpcode P.MULHW xoform3c $ \rT rB rA -> do
    comment "Multiply High Word (XO-form, RC=0)"
    comment "Multiply the low 32 bits of two registers, producing a 64 bit result."
    comment "Save the high 32 bits of the result into the output register"
    -- This is a high-word multiply, so we always need to perform it at 64 bits.
    -- Then we just take the high 32 bits of the result as our answer.
    let lhs = sext' 64 (lowBits 32 (Loc rA))
    let rhs = sext' 64 (lowBits 32 (Loc rB))
    let prod = bvmul lhs rhs
    -- Now we have to extract the high word (and store it in the low 32 bits of
    -- the output register)
    --
    -- NOTE: the high bits are technically undefined.  How do we want to
    -- represent that?
    let res = zext (highBits64 32 prod)
    defLoc rT res
    definePPCOpcodeRC P.MULHWo res $ do
      comment "Multiply High Word (XO-form, RC=1)"
  definePPCOpcode P.MULHWU xoform3c $ \rT rB rA -> do
    comment "Multiply High Word Unsigned (XO-form, RC=0)"
    let lhs = zext' 64 (lowBits 32 (Loc rA))
    let rhs = zext' 64 (lowBits 32 (Loc rB))
    let prod = bvmul lhs rhs
    let res = zext (highBits64 32 prod)
    defLoc rT res
    definePPCOpcodeRC P.MULHWUo res $ do
      comment "Multiply High Word Unsigned (XO-form, RC=1)"
  definePPCOpcode P.DIVW xoform3c $ \rT rB rA -> do
    comment "Divide Word (XO-form, RC=0)"
    let res = bvsdiv (sext (lowBits 32 (Loc rA))) (sext (lowBits 32 (Loc rB)))
    defLoc rT res
    definePPCOpcodeRC P.DIVWo res $ do
      comment "Divide Word (XO-form, RC=1)"
  definePPCOpcode P.DIVWU xoform3c $ \rT rB rA -> do
    comment "Divide Word Unsigned (XO-form, RC=0)"
    let res = bvudiv (sext (lowBits 32 (Loc rA))) (sext (lowBits 32 (Loc rB)))
    defLoc rT res
    definePPCOpcodeRC P.DIVWUo res $ do
      comment "Divide Word Unsigned (XO-form, RC=1)"
  defineOpcodeWithIP "ADDI" $ do
    comment "Add Immediate (D-form)"
    comment "We hand wrote this formula because it is one of the few that"
    comment "have special treatment of r0"
    rT <- param "rT" gprc naturalBV
    si <- param "si" s16imm (EBV 16)
    rA <- param "rA" gprc_nor0 naturalBV
    input rA
    input si
    let lhs = ite (isR0 (Loc rA)) (naturalLitBV 0x0) (Loc rA)
    defLoc rT (bvadd lhs (sext (Loc si)))
  defineOpcodeWithIP "ADDIS" $ do
    comment "Add Immediate Shifted (D-form)"
    comment "Like 'ADDI', we hand wrote this formula because it is one of the few that"
    comment "have special treatment of r0"
    rT <- param "rT" gprc naturalBV
    si <- param "si" s17imm (EBV 16)
    rA <- param "rA" gprc_nor0 naturalBV
    input rA
    input si
    let lhs = ite (isR0 (Loc rA)) (naturalLitBV 0x0) (Loc rA)
    let imm = concat (Loc si) (LitBV 16 0x0)
    defLoc rT (bvadd lhs (sext imm))

  definePPCOpcode P.ADDC xoform3c $ \rT rB rA -> do
    comment "Add Carrying (XO-form, RC=0)"
    input xer
    let len = bitSizeValue ?bitSize
    let eres = bvadd (zext' (len + 1) (Loc rA)) (zext' (len + 1) (Loc rB))
    let res = lowBits' len eres
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres))
    definePPCOpcodeRC P.ADDCo res $ do
      comment "Add Carrying (XO-form, RC=1)"
  defineOpcodeWithIP "ADDIC" $ do
    comment "Add Immediate Carrying (D-form)"
    (rT, rA, si) <- dformr0
    input xer
    let len = bitSizeValue ?bitSize
    let eres = bvadd (zext' (len + 1) (Loc rA)) (concat (LitBV 1 0x0) (sext (Loc si)))
    let res = lowBits' len eres
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres))
    defineRCVariant "ADDICo" res $ do
      comment "Add Immediate Carrying and Record (D-form)"
  defineOpcodeWithIP "SUBFIC" $ do
    comment "Subtract From Immediate Carrying (D-form)"
    (rT, rA, si) <- dformr0
    input xer
    let len = bitSizeValue ?bitSize
    let eres = bvsub (zext' (len + 1) (Loc rA)) (concat (LitBV 1 0x0) (sext (Loc si)))
    let res = lowBits' len eres
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres))
  definePPCOpcode P.SUBFC xoform3c $ \rT rB rA -> do
    comment "Subtract From Carrying (XO-form, RC=0)"
    input xer
    let len = bitSizeValue ?bitSize
    let eres0 = bvadd (bvnot (zext' (len + 1) (Loc rA))) (zext' (len + 1) (Loc rB))
    let eres1 = bvadd eres0 (LitBV (len + 1) 0x1)
    let res = lowBits' len eres1
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres1))
    definePPCOpcodeRC P.SUBFCo res $ do
      comment "Subtract From Carrying (XO-form, RC=1)"
  definePPCOpcode P.ADDE xoform3c $ \rT rB rA -> do
    comment "Add Extended (XO-form, RC=0)"
    input xer
    let len = bitSizeValue ?bitSize
    let eres0 = bvadd (zext' (len + 1) (Loc rA)) (zext' (len + 1) (Loc rB))
    let eres1 = bvadd eres0 (zext' (len + 1) (xerBit CA (Loc xer)))
    let res = lowBits' len eres1
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres1))
    definePPCOpcodeRC P.ADDEo res $ do
      comment "Add Extended (XO-form, RC=1)"
  defineOpcodeWithIP "ADDME" $ do
    comment "Add to Minus One Extended (XO-form, RC=0)"
    (rT, rA) <- xoform2
    input xer
    let len = bitSizeValue ?bitSize
    let eres0 = bvadd (zext' (len + 1) (Loc rA)) (zext' (len + 1) (xerBit CA (Loc xer)))
    let eres1 = bvsub eres0 (LitBV (len + 1) 0x1)
    let res = lowBits' len eres1
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres1))
    defineRCVariant "ADDMEo" res $ do
      comment "Add to Minus One Extended (XO-form, RC=1)"
  definePPCOpcode P.SUBFE xoform3c $ \rT rB rA -> do
    comment "Subtract From Extended (XO-form, RC=0)"
    input xer
    let len = bitSizeValue ?bitSize
    let eres0 = bvadd (bvnot (zext' (len + 1) (Loc rA))) (zext' (len + 1) (Loc rB))
    let eres1 = bvadd eres0 (zext' (len + 1) (xerBit CA (Loc xer)))
    let res = lowBits' len eres1
    defLoc rT res
    defLoc xer (updateXER CA (Loc xer) (highBits' 1 eres1))
    definePPCOpcodeRC P.SUBFEo res $ do
      comment "Subtract From Extended (XO-form, RC=1)"
  defineOpcodeWithIP "ADDZE" $ do
    comment "Add to Zero Extended (XO-form, RC=0)"
    (rT, rA) <- xoform2
    input xer
    let res = bvadd (Loc rA) (zext (xerBit CA (Loc xer)))
    defLoc rT res
    defineRCVariant "ADDZEo" res $ do
      comment "Add to Zero Extended (XO-form, RC=1)"
  defineOpcodeWithIP "SUBFZE" $ do
    comment "Subtract From Zero Extended (XO-form, RC=0)"
    (rT, rA) <- xoform2
    input xer
    let res = bvadd (bvnot (Loc rA)) (zext (xerBit CA (Loc xer)))
    defLoc rT res
    defineRCVariant "SUBFZEo" res $ do
      comment "Subtract From Zero Extended (XO-form, RC=1)"

  when (?bitSize == Size64) $ do
    -- Not valid in 32 bit mode
    definePPCOpcode P.MULLD xoform3c $ \rT rB rA -> do
      comment "Multiply Low Doubleword (XO-form, RC=0)"
      let prod = bvmul (sext' 128 (Loc rA)) (sext' 128 (Loc rB))
      let res = lowBits128 64 prod
      defLoc rT res
      definePPCOpcodeRC P.MULLDo res $ do
        comment "Multiply Low Doubleword (XO-form, RC=1)"
    definePPCOpcode P.MULHD xoform3c $ \rT rB rA -> do
      comment "Multiply High Doubleword (XO-form, RC=0)"
      let prod = bvmul (sext' 128 (Loc rA)) (sext' 128 (Loc rB))
      let res = highBits128 64 prod
      defLoc rT res
      definePPCOpcodeRC P.MULHDo res $ do
        comment "Multiply High Doubleword (XO-form, RC=1)"
    definePPCOpcode P.MULHDU xoform3c $ \rT rB rA -> do
      comment "Multiply High Doubleword Unsigned (XO-form, RC=0)"
      let prod = bvmul (zext' 128 (Loc rA)) (zext' 128 (Loc rB))
      let res = highBits128 64 prod
      defLoc rT res
      definePPCOpcodeRC P.MULHDUo res $ do
        comment "Multiply High Doubleword Unsigned (XO-form, RC=1)"
    definePPCOpcode P.DIVD xoform3c $ \rT rB rA -> do
      comment "Divide Doubleword Signed (XO-form, RC=0)"
      let res = bvsdiv (Loc rA) (Loc rB)
      defLoc rT res
      definePPCOpcodeRC P.DIVDo res $ do
        comment "Divide Doubleword Signed (XO-form, RC=1)"
    definePPCOpcode P.DIVDU xoform3c $ \rT rB rA -> do
      comment "Divide Doubleword Unsigned (XO-form, RC=0)"
      let res = bvudiv (Loc rA) (Loc rB)
      defLoc rT res
      definePPCOpcodeRC P.DIVDUo res $ do
        comment "Divide Doubleword Unsigned (XO-form, RC=1)"
