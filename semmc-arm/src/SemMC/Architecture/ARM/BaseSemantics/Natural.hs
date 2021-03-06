{-# LANGUAGE DataKinds #-}

module SemMC.Architecture.ARM.BaseSemantics.Natural
    where

import Data.Bits
import Data.Word
import SemMC.DSL


-- | All ARM registers are 32 bits wide for both A32 and T32.
naturalBitSize :: Num a => a
naturalBitSize = 32

-- | Type-level 'naturalBitSize'
type NaturalBitSize = 32

-- | Type for holding natural value words
type NaturalWord = Word32

-- | A zero value of the full register width
naturalZero :: NaturalWord
naturalZero = zeroBits

-- | A literal value bitvector of the full register width
naturalLitBV :: Integer -> Expr 'TBV
naturalLitBV n = LitBV naturalBitSize n

-- | A value as a bitvector of the full register width
naturalBV :: ExprTypeRepr 'TBV
naturalBV = EBV naturalBitSize
