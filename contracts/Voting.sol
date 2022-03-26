//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Voting {
    enum RequestTypes {
        AddMember,
        RemoveMember,
        Withdraw,
        Destroy
    }

    struct Request {
        address author;
        RequestTypes requestType;
        address addr;
        uint256 value;
        bool approved;
        bool accepted;
        uint256 proVotersCount;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) internal _requests;

    uint256 internal _requestsCounter;

    event RequestCreated(uint256 requestId);
    event InvitationSent(uint256 requestId, address indexed to);

    modifier onlyMember() virtual {
        require(false);
        _;
    }

    function requestsCounter() public view returns (uint256) {
        return _requestsCounter;
    }

    function checkRequestIsApprovedById(uint256 _id)
        public
        view
        returns (bool)
    {
        return _requests[_id].approved;
    }

    function checkRequestIsAcceptedById(uint256 _id)
        public
        view
        returns (bool)
    {
        return _requests[_id].accepted;
    }
    function checkMemberHasVotedById(uint256 _id) public view returns (bool) {
        return _requests[_id].voters[msg.sender];
    }

    function getRequestAuthorById(uint256 _id) public view returns (address) {
        return _requests[_id].author;
    }

    function getRequestTypeById(uint256 _id)
        public
        view
        returns (RequestTypes)
    {
        return _requests[_id].requestType;
    }

    function getRequestAddrById(uint256 _id) public view returns (address) {
        return _requests[_id].addr;
    }

    function getRequestValueById(uint256 _id) public view returns (uint256) {
        return _requests[_id].value;
    }

    function getRequestProVotersCountById(uint256 _id)
        public
        view
        returns (uint256)
    {
        return _requests[_id].proVotersCount;
    }

    function createRequest(
        uint256 _requestTypeIdx,
        uint256 _value,
        address _addr
    ) external onlyMember {
        require(
            _requestTypeIdx <= uint256(type(RequestTypes).max),
            "Invalid request type!"
        );

        if (_requestTypeIdx == uint8(RequestTypes.Withdraw)) {
            require(_value > 0 && _value <= address(this).balance);
        } else {
            require(_addr != address(0x0));
        }

        Request storage request = _requests[_requestsCounter];

        request.author = msg.sender;
        request.requestType = RequestTypes(_requestTypeIdx);
        request.addr = _addr;
        request.value = _value;
        request.proVotersCount = 1;
        request.approved = false;
        request.voters[msg.sender] = true;

        uint256 requestID = _requestsCounter;
        _requestsCounter++;

        emit RequestCreated(requestID);
        if (request.requestType == RequestTypes.AddMember)
            emit InvitationSent(requestID, request.addr);
        _tryApproveRequest(requestID);
    }

    function acceptRequest(uint256 _requestID) external onlyMember {
        require(
            _requests[_requestID].approved == false,
            "Request has already passed!"
        );
        require(
            _requests[_requestID].voters[msg.sender] == false,
            "Already voted to this request!"
        );
        _requests[_requestID].voters[msg.sender] = true;
        _requests[_requestID].proVotersCount++;
        _tryApproveRequest(_requestID);
    }

    function acceptInvitation(uint256 _requestID) external {
        require(_requests[_requestID].addr == msg.sender);
        require(
            _requests[_requestID].accepted == false,
            "Invitation already accepted!"
        );
        require(
            _requests[_requestID].requestType == RequestTypes.AddMember,
            "Wrong request id!"
        );
        _requests[_requestID].accepted = true;
        _tryApproveRequest(_requestID);
    }

    function _tryApproveRequest(uint256 _requestID) internal virtual {
        // uint256 goal = _getMajority(1); // override
        // if (
        //     _requests[_requestID].proVotersCount == goal &&
        //     _requests[_requestID].requestType != RequestTypes.AddMember
        // ) {
        //     _requests[_requestID].approved = true;
        // } else if (
        //     _requests[_requestID].proVotersCount == goal &&
        //     _requests[_requestID].requestType == RequestTypes.AddMember &&
        //     _requests[_requestID].accepted
        // ) {
        //     _requests[_requestID].approved = true;
        // }
    }

    function _getMajority(uint256 _total) internal pure returns (uint256) {
        return _total / 2 + 1;
    }
}
