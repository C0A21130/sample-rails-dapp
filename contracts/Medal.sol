// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "contracts/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Medal is ERC721URIStorage {

    constructor() ERC721("Medal", "TamaMedal") {}

    mapping(uint256 => uint256) private level;
    mapping(uint256 => address) private minterAddress;
    mapping(uint256 => string)  private minterName;

    /*
     * @titlle メダルミント
     * @notice NFTを発行するメソッド
     * @param id 発行するメダル番号
     * @param name 発行者の名前
    */
    function mint(uint256 id, string calldata name) public returns (uint256) {
        _mint(msg.sender, id);
        _setTokenURI(id, string(abi.encodePacked("http://10.203.92.57:5000/api/gaid/", Strings.toString(id))));

        minterAddress[id] = msg.sender;
        level[id] = 1;
        minterName[id] = name;
        
        return id;
    }

    /*
     * @titlle メダル交換
     * @notice NFTの所有者アドレスを変更するメソッド
     * @param _from 交換元のアドレス
     * @param _to 交換先のアドレス
     * @param _tokenId 交換するメダル番号
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    // メダル番号から現在のレベルを確認する関数
    function getLevel(uint256 tokenId) public view returns (uint256) {
        return level[tokenId];
    }

    // メダル番号から発行者のアドレスを確認する関数
    function getMinterAddress(uint256 tokenId) public view returns (address) {
        return minterAddress[tokenId];
    }

    // メダル番号から発行者の名前を確認する関数
    function getMinterName(uint256 tokenId) public view returns (string memory) {
        return minterName[tokenId];
    }

    //交換先の名前とアドレスを書き替える関数
    function changeMedalOwner(uint256 tokenId, address mAddress, string calldata mName) public {
        minterAddress[tokenId] = mAddress;
        minterName[tokenId] = mName;
        level[tokenId] += 1;
    }
}