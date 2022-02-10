// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Contract
 * @dev Handle election app
 */
contract ElectionContract {
/***************************************************************
                    VARIABLE DECLARATIONS
***************************************************************/

    /* Miscellaneous */
    address public responsibleAddress; // Address of the contract deployer, used to grant election editing permissions
    // Dates are stored in Unix epoch timestamp format (so only 32 bytes necessary)
    uint256 public startDate;
    uint256 public endDate;

    /* Candidates related */
    struct Candidate {
        uint voteCount;
    }
    mapping(address => Candidate) public candidates;   // Whole object to make a graph on front-side
    address[] public candidatesList;                   // To access the candidates' list easier within the candidate section
    uint public candidatesCount;                      // To emulate the mapping length

    /* Voters related */
    struct Voter {
        uint voteWeight;        // Vote weight, can increase when people delegate their vote to others
        bool hasVoted;          // If the voter has voted
        address votedFor;       // Address of the candidate voted for

        bool hasDelegated;      // If the voter delegated his vote to another member
        address delegatedTo;    // Address of the member the voter delegated his vote to
    }
    mapping(address => Voter) private voters;

/***************************************************************
                    CONTRACT INITIALIZATION
***************************************************************/

    /** 
     * @dev Initialize the candidates' pool
     * @param _candidates : addresses of candidates
     * @param _voters : addresses of voters
     * @param _startDate : election's starting date
     * @param _endDate : election's ending date
     */
    constructor(address[] memory _candidates, address[] memory _voters, uint32 _startDate, uint32 _endDate) {

        // Initialize who will be the election responsible (AKA contract deployer)
        responsibleAddress = msg.sender;    // 'msg.sender' is the current sender address
        candidatesList = _candidates;       // Store the candidates' list for a direct call

        // Initialize the candidates' pool
        candidatesCount = 0;
        for (uint i = 0; i < _candidates.length; i++) {
            Candidate storage candidate = candidates[_candidates[i]];
            candidate.voteCount = 0;
            candidatesCount++;
        }
        // Initialize default voters
        addVoters(_voters);

        // Initialize election dates
        startDate = _startDate;
        endDate = _endDate;
    }

/***************************************************************
                           MODIFIERS
***************************************************************/

/*----- For the Voters -----*/

    // Check if at the current date the election is open for votes
    modifier electionIsOpen() {
        require(startDate < block.timestamp, "The election hasn't started yet.");
        require(block.timestamp < endDate, "The election is finished.");
        _;
    }

    // Check if the election is finished to retrieve the winner
    modifier isFinished() {
        require(endDate < block.timestamp, "You can't ask for the election winner before its end.");
        _;
    }

    // Check if the voter can vote
    modifier canVote() {
        Voter memory voter = voters[msg.sender];
        require(voter.voteWeight != 0, "You are not allowed to vote.");
        require(!voter.hasVoted, "You already voted.");
        require(!voter.hasDelegated, "You delegated your vote.");
        _;
    }

    // Check if the voter can delegate
    modifier canDelegate() {
        Voter memory voter = voters[msg.sender];
        require(voter.voteWeight != 0, "You must be allowed to vote before delegating it.");
        require(!voter.hasVoted, "You already voted by yourself.");
        require(!voter.hasDelegated, "You already delegated your vote to someone else.");
        _;
    }

/*----- For the Deployer -----*/

    // Check if the sender is the election responsible, for permissions purpose
    modifier isResponsible() {
        require(msg.sender == responsibleAddress, "You don't have the required permission to perform this action.");
        _;
    }

    // Check if the responsible can edit the election dates
    modifier canEditDates() {
        require(block.timestamp < startDate, "You can only change the election dates before it started.");
        _;
    }

/***************************************************************
                           FUNCTIONS
***************************************************************/

/*----- For the Deployer -----*/

    // Add voters to the mapping pool
    function addVoters(address[] memory _voters) public isResponsible {
        for (uint i = 0; i < _voters.length; i++) {
            Voter storage voter = voters[_voters[i]];
            voter.voteWeight = 1;
            voter.hasVoted = false;
            voter.hasDelegated = false;
        }
    }

/*----- For the Voters -----*/

    // Handle a voter's vote
    function vote(address candidateAddress) public electionIsOpen canVote {
        // Retrieve voter's informations from sender's address
        Voter storage voter = voters[msg.sender];

        // Handle vote
        voter.hasVoted = true;
        voter.votedFor = candidateAddress;
        candidates[candidateAddress].voteCount += voter.voteWeight;
    }

    // Handle a voter's vote delegation
    function delegateVote(address newVoter) public canDelegate {
        // Other specific checks
        require(newVoter != msg.sender, "You can't delegate your vote to yourself.");
        require(voters[newVoter].voteWeight != 0, "You can only delegate your vote to someone allowed to vote too.");
        
        // Retrieve voter's informations from sender's address
        Voter storage voter = voters[msg.sender];

        // Handle delegation
        voter.hasDelegated = true;
        voter.delegatedTo = newVoter;
        voters[newVoter].voteWeight += voter.voteWeight;
        
        // If delegate already voted
        if (voters[newVoter].hasVoted) {
            candidates[voters[newVoter].votedFor].voteCount += voter.voteWeight;
        }
    }

// [DEMANDER au groupe si ajout d'un paramètre d'entrée 'authorizeBouncing/Propagation', en gros lorsque le gars à qui on veut déléguer son vote
// à lui même déléguer à un tiers, détermine si on autorise le rebond de notre délégation sur ce tiers ou non, avec un attribut d'objet.]
// Verify if the voter to which you want to delegate your vote hasn't done the same already
// require(voters[newVoter].hasDelegated = 0, "The person you want to delegate your vote to has already done the same.");

/*----- Getters -----*/

    // Get voter informations
    function getSpecificVoter() public view returns (Voter memory) {
        return voters[msg.sender];
    }

    // Get election's winner [MAYBE migrate to the front-side for cost concerns]
    function getWinner() public view isFinished returns (address winnerAddress) {
        uint256 maxVotesCount = 0;
        
        // Looking for candidate with the most votes
        for (uint256 i = 0; i < candidatesCount; i++) {
            if(candidates[candidatesList[i]].voteCount > maxVotesCount) {
                winnerAddress = candidatesList[i];
                maxVotesCount = candidates[candidatesList[i]].voteCount;
            }
        }
        return winnerAddress;
    }
}