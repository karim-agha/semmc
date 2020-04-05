{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImplicitParams #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

import           Control.Concurrent
import           Control.Exception
import qualified Data.ByteString as BS
import           Data.Parameterized.Classes
import qualified Data.Parameterized.Map as MapF
import qualified Data.Parameterized.Nonce as PN
import           Data.Parameterized.Some
import           Data.Proxy ( Proxy(..) )
import           Data.Semigroup
import qualified Dismantle.ARM.A32 as A32
import qualified Dismantle.ARM.T32 as T32

import qualified Lang.Crucible.Backend as CRUB
import qualified Lang.Crucible.Backend.Simple as S
import qualified SemMC.Architecture.AArch32 as ARM
import           SemMC.Architecture.ARM.Combined
import           SemMC.Architecture.ARM.Opcodes ( loadSemantics, ASLSemantics(..)
                                                , ASLSemanticsOpts(..))
import qualified SemMC.Formula.Formula as F
import qualified SemMC.Formula.Load as FL
import qualified SemMC.Formula.Env as FE
import qualified SemMC.Util as U
import           System.IO
import           Test.Tasty
import           Test.Tasty.HUnit
import qualified What4.Interface as CRU
import qualified What4.Expr.Builder as WB

main :: IO ()
main = do
  defaultMain tests


withTestLogging :: (U.HasLogCfg => IO a) -> IO a

withTestLogging op = do
  logOut <- newMVar []
  U.withLogging "testmain" (logVarEventConsumer logOut (const True)) $
   catch op $
       \(e :: SomeException) ->
           do threadDelay 10000
              -- the delay allows async log thread to make updates.  A
              -- delay is a kludgy hack, but this will only occur when
              -- the test has failed anyhow, so some extra punishment
              -- is not uncalled for.
              takeMVar logOut >>= (hPutStrLn stderr . concatMap U.prettyLogEvent)
              throwIO e


-- | A log event consumer that prints formatted log events to stderr.
logVarEventConsumer :: MVar [U.LogEvent] -> (U.LogEvent -> Bool) -> U.LogCfg -> IO ()
logVarEventConsumer logOut logPred =
  U.consumeUntilEnd logPred $ \e -> do
    modifyMVar logOut $ \l -> return (l ++ [e], ())


tests :: TestTree
tests = do testGroup "Read Formulas" [ testAll ]

testAll :: TestTree
testAll = testCase "testAll" $ withTestLogging $ do
  Some ng <- PN.newIONonceGenerator
  sym <- S.newSimpleBackend S.FloatIEEERepr ng
  WB.startCaching sym
  env <- FL.formulaEnv (Proxy @ARM.AArch32) sym
  sem <- loadSemantics (ASLSemanticsOpts { aslOptTrimRegs = True })
  lib <- withTestLogging $ FL.loadLibrary (Proxy @ARM.AArch32) sym env (funSemantics sem)
  let
    aconv :: (Some (A32.Opcode A32.Operand), BS.ByteString) -> (Some (ARMOpcode ARMOperand), BS.ByteString)
    aconv (o,b) = (mapSome A32Opcode o, b)

    tconv :: (Some (T32.Opcode T32.Operand), BS.ByteString) -> (Some (ARMOpcode ARMOperand), BS.ByteString)
    tconv (o,b) = (mapSome T32Opcode o, b)
  _ <- FL.loadFormulas sym env lib (map aconv $ a32Semantics sem)
  _ <- FL.loadFormulas sym env lib (map tconv $ t32Semantics sem)
  return ()
