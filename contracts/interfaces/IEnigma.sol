pragma solidity ^0.8.0;

import "./enigma/IEnigmaActions.sol";
import "./enigma/IEnigmaDataStructures.sol";
import "./enigma/IEnigmaErrors.sol";
import "./enigma/IEnigmaEvents.sol";
import "./enigma/IEnigmaView.sol";

interface IEnigma is IEnigmaActions, IEnigmaDataStructures, IEnigmaErrors, IEnigmaEvents, IEnigmaView {}
