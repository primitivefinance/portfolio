pragma solidity ^0.8.0;

import "./enigma/IEnigmaDataStructures.sol";
import "./enigma/IEnigmaErrors.sol";
import "./enigma/IEnigmaEvents.sol";
import "./enigma/IEnigmaView.sol";

interface IEnigma is IEnigmaDataStructures, IEnigmaErrors, IEnigmaEvents, IEnigmaView {}
