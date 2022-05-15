// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./enigma/IEnigmaActions.sol";
import "./enigma/IEnigmaDataStructures.sol";
import "./enigma/IEnigmaErrors.sol";
import "./enigma/IEnigmaEvents.sol";
import "./enigma/IEnigmaView.sol";

/// @title IEngima
/// @dev All the interfaces of the Enigma, so it can be imported with ease.
interface IEnigma is IEnigmaActions, IEnigmaDataStructures, IEnigmaErrors, IEnigmaEvents, IEnigmaView {

}
