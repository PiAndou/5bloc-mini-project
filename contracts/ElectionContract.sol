// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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
        uint256 voteCount;
    }
    mapping(address => Candidate) public candidates; // Whole object to make a graph on front-side
    address[] public candidatesList; // Just the candidates' list when the voter votes
    uint256 public candidatesCount = 0; // To emulate the mapping length

    /* Voters related */
    struct Voter {
        bool hasVoted; // If the voter has voted
        address votedFor; // Address of the candidate voted for
        uint256 voteWeight; // Vote weight, can increase when people delegate their vote to others
        bool hasDelegated; // If the voter delegated his vote to another member
        address delegatedTo; // Address of the member the voter delegated his vote to
    }
    mapping(address => Voter) private voters;

    /***************************************************************
                    VARIABLE INITIALIZATIONS
***************************************************************/

    /**
     * @dev Initialize the candidates' pool
     * @param _candidates : addresses of candidates
     * @param _voters : addresses of voters
     * @param _startDate : election's starting date
     * @param _endDate : election's ending date
     */
    constructor(
        address[] memory _candidates,
        address[] memory _voters,
        uint256 _startDate,
        uint256 _endDate
    ) {
        // Initialize who will be the election responsible (AKA contract deployer)
        responsibleAddress = msg.sender; // 'msg.sender' is the current sender address
        candidatesList = _candidates; // Store the candidates' list for a direct call

        // Initialize the candidates' pool
        for (uint256 i = 0; i < _candidates.length; i++) {
            Candidate storage candidate = candidates[_candidates[i]];
            candidate.voteCount = 0;
            candidatesCount++;
        }
        // Initialize the voters' list
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
        require(startDate <= block.timestamp, "The election is not yet open.");
        require(endDate >= block.timestamp, "The election is closed.");
        _;
    }

    // Check if the voter can vote
    modifier canVote() {
        Voter memory voter = voters[msg.sender];
        require(voter.voteWeight != 0, "Can are not allowed to vote.");
        require(!voter.hasVoted, "You already voted.");
        require(!voter.hasDelegated, "You delegated your vote.");
        _;
    }

    // Check if the voter can delegate
    modifier canDelegate() {
        Voter memory voter = voters[msg.sender];
        require(
            voter.voteWeight != 0,
            "You must be allowed to vote before delegating it."
        );
        require(!voter.hasVoted, "You already voted by yourself.");
        require(
            !voter.hasDelegated,
            "You already delegated your vote to someone else."
        );
        _;
    }

    /*----- For the Deployer -----*/

    // Check if the sender is the election responsible, for permissions purpose
    modifier isResponsible() {
        require(
            msg.sender == responsibleAddress,
            "You don't have the required permission to perform this action."
        );
        _;
    }

    // Check if the responsible can edit the election starting date
    modifier canEditStartDate() {
        require(
            block.timestamp < startDate,
            "You can't change the starting date of the election after it started."
        );
        _;
    }

    // Check if the election is finished to retrieve the winner
    modifier isFinished() {
        require(
            endDate < block.timestamp,
            "You can't ask for the election winner before it's end."
        );
        _;
    }

    /***************************************************************
                           FUNCTIONS
***************************************************************/

    /*----- For the Deployer -----*/

    // Add voters to the mapping pool
    function addVoters(address[] memory _voters) public isResponsible {
        for (uint256 i = 0; i < _voters.length; i++) {
            Voter storage voter = voters[_voters[i]];
            voter.hasVoted = false;
            voter.voteWeight = 1;
            voter.hasDelegated = false;
        }
    }

    // [En BONUS]
    function editDates(uint256 startValue, uint256 endValue)
        public
        isResponsible
    {}

    /*----- For the Voters -----*/

    function vote(address candidateAddress) public electionIsOpen canVote {
        // Retrieve voter's informations from sender's address
        Voter storage voter = voters[msg.sender];

        // Handle vote
        voter.hasVoted = true;
        voter.votedFor = candidateAddress;
        candidates[candidateAddress].voteCount += voter.voteWeight;
    }

    // [En BONUS]
    function changeVote(address candidateAddress) public {}

    // [DEMANDER au groupe si ajout d'un paramètre d'entrée 'authorizeBouncing/Propagation', en gros lorsque le gars à qui on veut déléguer son vote
    // à lui même déléguer à un tiers, détermine si on autorise le rebond de notre délégation sur ce tiers ou non. Voire un attribut d'objet.]
    // Verify if the voter to which you want to delegate your vote hasn't done the same already
    // require(voters[newVoter].hasDelegated = 0, "The person you want to delegate your vote to has already done the same.");

    function delegateVote(address newVoter) public canDelegate {
        // Other specific checks
        // [OPTION : Ajouter check si la personne à qui on délègue peut voter]
        require(
            newVoter != msg.sender,
            "You can't delegate your vote to yourself."
        );

        // Retrieve voter's informations from sender's address
        Voter storage voter = voters[msg.sender];

        // Handle delegation
        voter.hasDelegated = true;
        voter.delegatedTo = newVoter;
        voters[newVoter].voteWeight++;
    }

    /*----- Getters -----*/

    // Get candidates' pool
    // ? see https://ethereum.stackexchange.com/a/65590
    // but not working !!!
    // function getAllCandidates() public view returns (address[] memory) {
    //     address[] memory ret = new address[](candidatesCount);

    //     for (uint256 i = 0; i < candidatesCount; i++) {
    //         ret[i] = candidatesList[i];
    //     }

    //     return ret;
    // }

    // Get current voter informations
    function getCurrentVoter() public view returns (Voter memory) {
        return voters[msg.sender];
    }

    // Get election's winner [MAYBE migrate on the front-side]
    function getWinner()
        public
        view
        isFinished
        returns (address winnerAddress)
    {
        uint256 maxVotesCount = 0;

        // Looking for candidate with the most votes
        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidates[candidatesList[i]].voteCount > maxVotesCount) {
                winnerAddress = candidatesList[i];
                maxVotesCount = candidates[candidatesList[i]].voteCount;
            }
        }
        return winnerAddress;
    }
}
