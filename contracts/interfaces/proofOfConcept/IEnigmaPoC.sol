// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./enigma/IEnigmaActionsPoC.sol";
import "./enigma/IEnigmaDataStructuresPoC.sol";
import "./enigma/IEnigmaErrorsPoC.sol";
import "./enigma/IEnigmaEventsPoC.sol";
import "./enigma/IEnigmaViewPoC.sol";

/// @title IEngima
/// @dev All the interfaces of the Enigma, so it can be imported with ease.
interface IEnigmaPoC is
    IEnigmaActionsPoC,
    IEnigmaDataStructuresPoC,
    IEnigmaErrorsPoC,
    IEnigmaEventsPoC,
    IEnigmaViewPoC
{

}
