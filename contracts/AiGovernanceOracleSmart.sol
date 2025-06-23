// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AiGovernanceOracle {
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votingDeadline;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool aiRecommendation;
        uint256 aiConfidenceScore;
        string aiAnalysis;
        ProposalStatus status;
    }
    
    enum ProposalStatus {
        Active,
        Passed,
        Rejected,
        Executed
    }
    
    struct Voter {
        bool hasVoted;
        bool vote;
        uint256 weight;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Voter)) public votes;
    mapping(address => uint256) public votingPower;
    mapping(address => bool) public authorizedAiOracles;
    
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MIN_VOTING_POWER = 100;
    uint256 public quorumPercentage = 30; // 30% quorum required
    uint256 public totalVotingPower;
    
    address public admin;
    address public primaryAiOracle;
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 deadline
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    
    event AiAnalysisProvided(
        uint256 indexed proposalId,
        bool recommendation,
        uint256 confidenceScore,
        string analysis
    );
    
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedAi() {
        require(authorizedAiOracles[msg.sender], "Only authorized AI oracles can perform this action");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        votingPower[msg.sender] = 1000; // Admin gets initial voting power
        totalVotingPower = 1000;
    }
    
    function createProposal(
        string memory title,
        string memory description
    ) external returns (uint256) {
        require(votingPower[msg.sender] >= MIN_VOTING_POWER, "Insufficient voting power to create proposal");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        
        uint256 proposalId = proposalCount++;
        uint256 deadline = block.timestamp + VOTING_PERIOD;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            votingDeadline: deadline,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            aiRecommendation: false,
            aiConfidenceScore: 0,
            aiAnalysis: "",
            status: ProposalStatus.Active
        });
        
        emit ProposalCreated(proposalId, msg.sender, title, deadline);
        return proposalId;
    }
    
    function castVote(uint256 proposalId, bool support) external proposalExists(proposalId) {
        require(votingPower[msg.sender] > 0, "No voting power");
        require(block.timestamp < proposals[proposalId].votingDeadline, "Voting period ended");
        require(!votes[proposalId][msg.sender].hasVoted, "Already voted");
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal not active");
        
        uint256 weight = votingPower[msg.sender];
        
        votes[proposalId][msg.sender] = Voter({
            hasVoted: true,
            vote: support,
            weight: weight
        });
        
        if (support) {
            proposals[proposalId].forVotes += weight;
        } else {
            proposals[proposalId].againstVotes += weight;
        }
        
        emit VoteCast(proposalId, msg.sender, support, weight);
        
        // Check if proposal can be finalized
        _checkAndFinalizeProposal(proposalId);
    }
    
    function provideAiAnalysis(
        uint256 proposalId,
        bool recommendation,
        uint256 confidenceScore,
        string memory analysis
    ) external onlyAuthorizedAi proposalExists(proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal not active");
        require(confidenceScore <= 100, "Confidence score must be between 0-100");
        require(bytes(analysis).length > 0, "Analysis cannot be empty");
        
        proposals[proposalId].aiRecommendation = recommendation;
        proposals[proposalId].aiConfidenceScore = confidenceScore;
        proposals[proposalId].aiAnalysis = analysis;
        
        emit AiAnalysisProvided(proposalId, recommendation, confidenceScore, analysis);
    }
    
    function _checkAndFinalizeProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 requiredQuorum = (totalVotingPower * quorumPercentage) / 100;
        
        // Check if voting period ended or quorum reached
        if (block.timestamp >= proposal.votingDeadline || totalVotes >= requiredQuorum) {
            if (totalVotes >= requiredQuorum && proposal.forVotes > proposal.againstVotes) {
                proposal.status = ProposalStatus.Passed;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
            
            emit ProposalExecuted(proposalId, proposal.status == ProposalStatus.Passed);
        }
    }
    
    // Admin functions
    function setVotingPower(address user, uint256 power) external onlyAdmin {
        uint256 oldPower = votingPower[user];
        votingPower[user] = power;
        totalVotingPower = totalVotingPower - oldPower + power;
    }
    
    function authorizeAiOracle(address oracle) external onlyAdmin {
        authorizedAiOracles[oracle] = true;
        if (primaryAiOracle == address(0)) {
            primaryAiOracle = oracle;
        }
    }
    
    function revokeAiOracle(address oracle) external onlyAdmin {
        authorizedAiOracles[oracle] = false;
        if (primaryAiOracle == oracle) {
            primaryAiOracle = address(0);
        }
    }
    
    function setQuorumPercentage(uint256 newQuorum) external onlyAdmin {
        require(newQuorum > 0 && newQuorum <= 100, "Invalid quorum percentage");
        quorumPercentage = newQuorum;
    }
    
    // View functions
    function getProposalDetails(uint256 proposalId) external view proposalExists(proposalId) 
        returns (
            address proposer,
            string memory title,
            string memory description,
            uint256 deadline,
            uint256 forVotes,
            uint256 againstVotes,
            ProposalStatus status,
            bool aiRecommendation,
            uint256 aiConfidenceScore,
            string memory aiAnalysis
        ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votingDeadline,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.status,
            proposal.aiRecommendation,
            proposal.aiConfidenceScore,
            proposal.aiAnalysis
        );
    }
    
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return votes[proposalId][voter].hasVoted;
    }
    
    function getVote(uint256 proposalId, address voter) external view returns (bool support, uint256 weight) {
        Voter storage voterInfo = votes[proposalId][voter];
        return (voterInfo.vote, voterInfo.weight);
    }
}
