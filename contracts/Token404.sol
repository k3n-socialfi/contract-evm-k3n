// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ERC404/ERC404.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
contract Token404 is ERC404 {

    string public baseTokenURI;
    constructor() ERC404('Token404', 'TOKEN404', 18, 10000, msg.sender) {
    balanceOf[msg.sender] = 10000 * 10 ** 18;
    setWhitelist(msg.sender, true);
  }

  function setTokenURI(string memory _tokenURI) public onlyOwner {
    baseTokenURI = _tokenURI;
  }

  function setNameSymbol(string memory _name, string memory _symbol) public onlyOwner {
    _setNameSymbol(_name, _symbol);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    if (bytes(baseTokenURI).length > 0) {
      return string.concat(baseTokenURI, Strings.toString(id));
    } else {
      uint8 seed = uint8(bytes1(keccak256(abi.encodePacked(id))));
      string memory image;
      string memory color;

      if (seed <= 127) {
        // 50%
        image = '';
        color = 'Orange Token';
      } else if (seed <= 255) {
        // 50%
        image = '';
        color = 'Green Token';
      }

      string memory jsonPreImage = string.concat(
        string.concat(
          string.concat('{"name": "Token404 #', Strings.toString(id)),
          '","description":"A collection of 10,000 Replicants enabled by ERC404 - an experimental token standard.","external_url":"","image":"'
        ),
        image
      );
      string memory jsonPostImage = string.concat('","attributes":[{"trait_type":"Color","value":"', color);
      string memory jsonPostTraits = '"}]}';

      return
        string.concat(
          'data:application/json;utf8,',
          string.concat(string.concat(jsonPreImage, jsonPostImage), jsonPostTraits)
        );
    }
  }
}