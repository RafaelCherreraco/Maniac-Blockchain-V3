// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// IERC721 is the ERC721 interface that we´ll use to make Maniac´s NFT ERC721 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// IERC721Receiver must be implemented to accept safe transfers
// It is included on the ERC721 standard
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// ERC165 is used to declare interface support for IERC721
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// SafeMath will be used for every math operation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Address will provide functions such as .isContract verification
import "@openzeppelin/contracts/utils/Address.sol";

// The "is" keywork is used to inherit functions and keywords from external contracts.
// In this case "Artwork" inherits from the "IERC721" and "ERC165" contracts.

// Interface that will ingerits to the contracts will be looking for a problem...
contract Artwork is ERC165, IERC721 {
    // Uses OpenZeppelin´s SafeMath library to perform arithmetic operations safely.
    using SafeMath for uint256;
    // Use OpenZeppelin´s address library to validate whether an address is
    // is a contract or not
    using Address for address;

    // 161 take a reference to the three first numbers 
    // from number phi (1,61803)
    uint256 constant artDigits = 161;
    uint256 constant artModuls = 161**artDigits;


    //ERC165 indentifier to ERC721 got from
    // bytes4(keccak256("onERC721Received(address,adress,uint256,bytes)"))
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    struct Maniac {
        string name;
        uint art;
    }

    // Creates an empty array of Artwork structs
    Artwork[] public NFTmaniac;

    // Mapping from id of Artwork to it´s owner´s address
    mapping(uint256 => address) public NFTmaniacToOwner;

    // Mapping from owner´s address to number of owned token
    mapping(address => uint256) public ownerNFTmaniacCount;

    // Mapping to validate that art is not already taken
    mapping(uint256 => bool) public artNFTmaniacExists;

    // Mapping from Token ID to approved address
    mapping(uint256 => address) NFTmaniacApprovals;

    // Owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;


    // Check if Artwork is unique and does not exist yet
    modifier isUnique(uint256 _art) {
        require(
            !artArtworkExists[_art],
            "Nft with such art already exist."
        );
        _;
    }

    // Creates a random Artwork from string (name)
    function createRandomArtwork(string memory _name) public {
        uint256 randArt = generateRandomArt(_name, msg.sender);
        _createArtwork(_name, randArt);
    }

    // Generates random ART from string (name) and address of the owner (creator)
    function generateRandomArt(string memory _str, address _owner)
    public
    pure
    returns (
        // Function marked as "pure" promise not to read from or modify the state
        uint256
    )
    {
        // Generates random uint from string (name) + address (owner)
        uint256 rand = uint256(keccak256(abi.encodePacked(_str))) + uint256(uint160(address(_owner)));
        rand = rand.mod(artModulus);
        return rand;
    }

    // Internal function to create a random Artwork from string (name) and Art
    function _createArtwork(string memory _name, uint256 _art) 
        internal
        // The "internal" keyword means this fucntion is only visible
        // Within this contract and contracts that derive this contract
        // "isUnique" is a function modifier that checks if the Artwork already exists
        isUnique(_art)
    {
        // Adds Artwork to array of Artworks and get ID
        NFTmaniac.pus(Artwork(_name, _art));
        uint256 id = (NFTmaniac.length.sub(1));

        // Mark as existent NFTmaniac name and art
        artArtworkExists[_art] = true;

        // Checks that Artwork owner is the same as current user
        assert(NFTmaniacToOwner[id] == address(0));

        // Maps the Artwork to the owner
        NFTmaniacToOwner[id] = msg.sender;
        ownerArtworkCount[msg.sender] = ownerArtworkCount[msg.sender].add(
            1
        );

    }
        // Returns array of Artwork found by owner
    function getArtworkByOwner(address _owner) 
        public
        view
        returns (
            // Functions marked as "view" promise not to modify state
            uint256[] memory
        )
    
    {
        // Uses the "memory" storage location to store values only for the 
        // lifecycle of this function call
        uint256 [] memory result = new uint256[](ownerArtworkCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < NFTmaniac.length; i++) {
            if (NFTmaniacToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // Returns count if Artwork by address
    function balanceOf(address _owner)
        public
        override
        view
        returns (uint256 _balance)
    {
        return ownerArtworkCount[_owner];
    }

    // Returns owner of the Artwork found by id
    function ownerOf(uint256 _NFTmaniacId)
        public
        override
        view
        returns (uint256 _balance)
    {
        address owner = NFTmaniacToOwner[_NFTmaniacId];
        require(owner != address(0), "Invalid Artwork ID");
        return owner;
    }

    // Safely transfer the ownership of a given tojen ID to another address
    // If the target address is a contract, it must implement "onERC721Received",
    // wich is called upon a dafe transfer, and return the magic value
    // "bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))";
    // otherwise, the transfer is reverted.

    function safeTransferFrom (
        address from,
        address to,
        uint256 NFTmaniacId
    ) public override {
        // solium-disable-next-line arg-overflow
        safeTranferFrom(from, to, NFTmaniacId, "");
    }

    // Transfers Artwork and ownership of the other address
    function transferFrom(
        address _from,
        address _to,
        uint256 _NFTmaniacId
    ) public override {
        require(_from != address(0) && _to != address(0), "Invalid address.");
        require(_exists(_NFTmaniacId), "Artwork does not exist.");
        require(_from != _to, "Cannot transfer to the same address.")
        ;
        require(
            _isApproveOrOwner(msg.sender, _NFTmaniacId),
            "Address is not approved."
        );

        ownerArtworkCount[_to] = ownerArtworkCount[_to].add(1);
        ownerArtworkCount[_from] = ownerArtworkCount[_from].sub(1);
        NFTmaniacToOwner[_NFTmaniacId] = _to;

        // Emits event defined in the imported IERC721 contract
        emit Transfer(_from, _to, _NFTmaniacId);
        _clearApproval(_to, NFTmaniacId);
    }

    // Checks if Artwork exists
    function _exists(uint256 NFTmaniacId) internal view returns (bool) {
        address owner = NFTmaniacToOwner[NFTmaniacId];
        return owner != address(0);
    }

    // Checks if address is owner or is approved to transfer Artwork
    function _isApprovedOrOwner(address spender, uint256 NFTmaniacId)
        internal
        view
        returns(bool)
    {
        address owner = NFTmaniacToOwner[NFTmaniacId];
        // Disable solium check because of
        // solium-disable-next-line operator-whitespace
        return (spender == owner ||
            getApproved(NFTmaniacId) == spender || 
            isApprovedForAll(owner, spender));
    }

    /** 
    - Private function to clear current approval of a given token ID
    - Reverts if the given address is not indeed the owner of the token
     */
     function _clearApproval(address owner, uint256 _avatheeerId) private {
         require(
             NFTmaniacToOwner[_NFTmaniacId] == owner,
             "Must be NFTmaniac owner."
         );
         require(_exists(_NFTmaniacId), "Artwork does not exist,");
         if(NFTmaniacApprovals[_NFTmaniacId] != address(0)) {
             NFTmaniacApprovals[_NFTmaniacId] = address(0);
         }
    }

    // Approves other address to transfer awnership of Artwork
    function approve(address _to, uin256 _NFTmaniacId) public override {
        require(
            msg.sender == NFTmaniacToOwner[_NFTmaniacId],
            "Must be the Artwork owner."
        );
        NFTmaniacApprovals[_NFTmaniacId] = _to;
        emit Approval(msg.sender, _to, _NFTmaniacId);
    }

    // Returns approved address for specific Artwork
    function getApproved(uint256 _NFTmaniacId)
        public
        override
        view
        returns (address operator)
    {
        require(_exists(_NFTmaniacId), "Artwork does not exist.");
        return NFTmaniacApprovals[_NFTmaniacId];
    }

    // Sets or unsets the approval of a given operator
    // An operator is allowed to transfer all tokens of the sender on their behalf

    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, "Cannor approve own address");
        operatorApprovals[mag.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    // Tells whether am operator is approved by a given owner
    function isApprovedForAll(address owner, address operator)
        public
        override
        view
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }
    /**
     * Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`;
     * otherwise, the transfer is reverted.
     */

    function safeTransferFrom(
        address from,
        address to,
        uint256 NFTmaniacId,
        bytes memory _data
    ) public override {
        transferFrom(from, to, NFTmaniacId);
        require(
            _checkOnERC721Received(from, to, NFTmaniacId, _data),
            "Must implement on ERC721Received."
        );
    }

    //Internal function to invoke `onERC721Received` on a target address
    // The call is not executed if the target address is not a contract
     
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 NFTmaniacId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            NFTmaniacId,
            _data
        );
        return (retval == _ERC721_RECEIVED);
    }

    // Burns a Artwork - destroys Token completely
    // The `external` function modifier means this function is
    // part of the contract interface and other contracts can call it

    function burn(uint256 _NFTmaniacId) external {
        require(msg.sender != address(0), "Invalid address.");
        require(_exists(_NFTmaniacId), "Artwork does not exist.");
        require(
            _isApprovedOrOwner(msg.sender, _NFTmaniacId),
            "Address is not approved."
        );

        ownerArtworkCount[msg.sender] = ownerArtworkCount[msg.sender].sub(
            1
        );
        NFTmaniacToOwner[_NFTmaniacId] = address(0);
    }

    // Takes ownership of Arwork - only for approved users
    function takeOwnership(uint256 _NFTmaniacId) public {
        require(
            _isApprovedOrOwner(msg.sender, _NFTmaniacId),
            "Address is not approved."
        );
        address owner = ownerOf(_NFTmaniacId);
        transferFrom(owner, msg.sender, _NFTmaniacId);
    }
    // Is estimated than the ERC721SmartContractManiac finished here, by the way, maybe in the future it will change some things in the contract
}