(* =====================================================================
   SECTION: OverRider_Manager  (V12_1110_6) - ladder as equations
   ===================================================================== *)
// Rung 0 "Cancelling function"
//   ControlVoltage AND NOT StartMotor_Cmd                -> (R) OverRider_RaiseUp
//   ... AND NOT I_OR_Auto_OS AND NOT I_OR_Cont_OS       -> (R) OverRider_Lock
//   ... AND NOT I_OR_Hoover_Mode                         -> (R) UwDiamReached, (R) RollEnd_Active
//   (UwDiamReached / RollEnd_Active are never SET any more: roll-end photocell removed)
// Rung 1 "Select the operating mode"
//   StartMotor_Cmd AND I_OR_Hoover_Mode AND I_OR_Auto_OS AND NOT OverRider_Hoover -> ( OverRider_Auto )
//   StartMotor_Cmd AND I_OR_Hoover_Mode AND I_OR_Cont_OS AND NOT OverRider_Auto   -> ( OverRider_Hoover )
// Rung 2 "Rewinder Over Rider Hoover control"
//   StartMotor_Cmd AND I_OR_Hoover_Mode AND ((OverRider_Auto AND UwDiamReached) OR OverRider_Hoover):
//     NOT I_OR_Position_Sens -> T_PosPresOff (TON TimPosPresOff)
//     I_OR_Position_Sens     -> T_PosPresOn  (TON TimPosPresOn)
//     T_PosPresOn.Q  -> (S) OverRider_Lock, (R) OverRider_RaiseUp
//     T_PosPresOff.Q -> (R) OverRider_Lock, (S) OverRider_RaiseUp
// Rung 3 "Rider roll raise command"         NOT ControlVoltage        -> (S) OverRider_RaiseUp
// Rung 4 "Rider roll raise command Reset"   RISING(I_ControlVoltage)  -> (R) OverRider_RaiseUp
