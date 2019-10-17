bits(N*M) Replicate(bits(N) bv)
    return Replicate(bv, M);

integer sizeOf(bits(N) bv)
    return N;

constant integer LOG2_TAG_GRANULE=4;
constant integer TAG_GRANULE=2 ^ LOG2_TAG_GRANULE;


enumeration __ExecutionStatus { __StatusNormal,
                                __StatusUndefined,
                                __StatusUnpredictable,
                                __StatusException,
                                __StatusAssertionFailure,
                                __StatusEndInstruction
                              };

__ExecutionStatus __CurrentExecutionStatus;

boolean IsExecutionHalted()
  return __CurrentExecutionStatus != __StatusNormal;

ASLHaltExecution(__ExecutionStatus status)
  __CurrentExecutionStatus = status;
  return;

EndOfInstruction()
  ASLHaltExecution(__StatusEndInstruction);
  return;



bits(4) AArch32.SetDefaultCond()
  if __ThisInstrEnc IN {InstrEnc_A64, InstrEnc_A32} || PSTATE.IT<3:0> == Zeros(4) then
      __currentCond = 0xE<3:0>;
  else
      __currentCond = PSTATE.IT<7:4>;
  return cond;

ConsumptionOfSpeculativeDataBarrier()
    return;

SpeculativeStoreBypassBarrierToPA()
    return;

SpeculationBarrier()
    return;

SpeculativeStoreBypassBarrierToVA()
    return;

SynchronizeErrors()
    return;

bits(64) AArch64.SysRegRead(integer op0, integer op1, integer crn, integer crm, integer op2)
    assert FALSE;
    reg = bits(64) UNKNOWN;
    return reg;

ReservedEncoding()
    return;

boolean IsPhysicalSErrorPending()
    ret = boolean UNKNOWN;
    return ret;

// We can likely stub these out safely
(boolean,boolean) AArch32.BreakpointValueMatch(integer n, bits(32) vaddress, boolean linked_to)
  return (FALSE, FALSE);


boolean AArch64.BreakpointValueMatch(integer n, bits(64) vaddress, boolean linked_to)
  return FALSE;

boolean IsBlockDescriptorNTBitValid()
  return FALSE;

bits(11) LSInstructionSyndrome()
  assert FALSE;
  ret = bits(11) UNKNOWN;
  return ret;

TraceSynchronizationBarrier()
  assert FALSE;
  return;

__abort()
  assert FALSE;
  return;

boolean AArch32.WatchpointMatch(integer n, bits(32) vaddress, integer size, boolean ispriv,
                                 boolean iswrite)
  return FALSE;

boolean AArch64.WatchpointMatch(integer n, bits(64) vaddress, integer size, boolean ispriv,
                                AccType acctype, boolean iswrite)
  return FALSE;

// We assume that the MMU is disabled and address translation is not occuring
TLBRecord AArch64.TranslationTableWalk(bits(52) ipaddress, bit s1_nonsecure, bits(64) vaddress,
                                       AccType acctype, boolean iswrite, boolean secondstage,
                                       boolean s2fs1walk, integer size)
  assert FALSE;
  TLBRecord result;
  return result;

TLBRecord AArch32.TranslationTableWalkLD(bits(40) ipaddress, bits(32) vaddress,
                                         AccType acctype, boolean iswrite, boolean secondstage,
                                         boolean s2fs1walk, integer size)
  assert FALSE;
  TLBRecord result;
  return result;

TLBRecord AArch32.TranslationTableWalkSD(bits(32) vaddress, AccType acctype, boolean iswrite,
                                         integer size)
  assert FALSE;
  TLBRecord result;
  return result;