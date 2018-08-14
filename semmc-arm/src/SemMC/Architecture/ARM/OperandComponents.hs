{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
module SemMC.Architecture.ARM.OperandComponents (
  OperandComponents(..)
  ) where

import           GHC.TypeLits ( Symbol )
import           Data.Parameterized.Classes ( ShowF, showF )
import           What4.BaseTypes
import qualified What4.Interface as WI

import qualified SemMC.Architecture as A

data OperandComponents arch sym (s :: Symbol) where
  OCAddrmodeImm12 :: { addrmodeImm12Reg :: A.Location arch (BaseBVType 32)
                     , addrmodeImm12RegExpr :: WI.SymExpr sym (BaseBVType 32)
                     , addrmodeImm12OffsetExpr :: WI.SymExpr sym (BaseBVType 12)
                     , addrmodeImm12AddExpr :: WI.SymExpr sym (BaseBVType 1)
                     }
                  -> OperandComponents arch sym s
  OCT2SoReg :: { t2SoRegReg :: A.Location arch (BaseBVType 32)
               , t2SoRegRegExpr :: WI.SymExpr sym (BaseBVType 32)
               , t2SoRegImmExpr :: WI.SymExpr sym (BaseBVType 5)
               , t2SoRegShiftTypeExpr :: WI.SymExpr sym (BaseBVType 2)
               }
            -> OperandComponents arch sym s
  OCTAddrModeIs4 :: { addrmodeIs4Reg :: A.Location arch (BaseBVType 32)
                    , addrmodeIs4RegExpr :: WI.SymExpr sym (BaseBVType 32)
                    , addrmodeIs4ImmExpr :: WI.SymExpr sym (BaseBVType 5)
                    }
                 -> OperandComponents arch sym s
  OCTAddrModeIs2 :: { addrmodeIs12Reg :: A.Location arch (BaseBVType 32)
                    , addrmodeIs12RegExpr :: WI.SymExpr sym (BaseBVType 32)
                    , addrmodeIs12ImmExpr :: WI.SymExpr sym (BaseBVType 5)
                    }
                 -> OperandComponents arch sym s
  OCSoRegReg :: { soRegRegReg1 :: A.Location arch (BaseBVType 32)
                , soRegRegReg1Expr :: WI.SymExpr sym (BaseBVType 32)
                , soRegRegReg2 :: A.Location arch (BaseBVType 32)
                , soRegRegReg2Expr :: WI.SymExpr sym (BaseBVType 32)
                , soRegRegTypeExpr :: WI.SymExpr sym (BaseBVType 2)
                }
             -> OperandComponents arch sym s
  OCSoRegImm :: { soRegImmReg :: A.Location arch (BaseBVType 32)
                , soRegImmRegExpr :: WI.SymExpr sym (BaseBVType 32)
                , soRegImmShiftTypeExpr :: WI.SymExpr sym (BaseBVType 2)
                , soRegImmImmExpr :: WI.SymExpr sym (BaseBVType 5)
                }
             -> OperandComponents arch sym s
  OCLdstSoReg :: { ldstSoRegBaseLoc :: A.Location arch (BaseBVType 32)
                 , ldstSoRegBaseExpr ::  WI.SymExpr sym (BaseBVType 32)
                 , ldstSoRegOffsetLoc :: A.Location arch (BaseBVType 32)
                 , ldstSoRegOffsetExpr :: WI.SymExpr sym (BaseBVType 32)
                 , ldstSoRegAddExpr :: WI.SymExpr sym (BaseBVType 1)
                 , ldstSoRegImmExpr :: WI.SymExpr sym (BaseBVType 5)
                 , ldstSoRegTypeExpr :: WI.SymExpr sym (BaseBVType 2)
                 }
              -> OperandComponents arch sym s

instance (WI.IsExpr (WI.SymExpr sym), ShowF (A.Location arch)) => Show (OperandComponents arch sym s) where
  show oc =
    case oc of
      OCAddrmodeImm12 r re oe ae -> unwords [ "OCAddrmodeImm12"
                                            , showF r
                                            , show (WI.printSymExpr re)
                                            , show (WI.printSymExpr oe)
                                            , show (WI.printSymExpr ae)
                                            ]

instance (WI.IsExpr (WI.SymExpr sym), ShowF (A.Location arch)) => ShowF (OperandComponents arch sym)
