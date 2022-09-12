// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./enigma/IEnigmaActions.sol";
import "./enigma/IEnigmaEvents.sol";
import "./enigma/IEnigmaGetters.sol";

/// @title IEngima
/// @dev All the interfaces of the Enigma, so it can be imported with ease.
interface IEnigma is IEnigmaActions, IEnigmaEvents, IEnigmaGetters {

}
