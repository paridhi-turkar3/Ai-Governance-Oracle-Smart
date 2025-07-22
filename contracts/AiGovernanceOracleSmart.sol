function getActiveProposals() external view returns (Proposal[] memory) {
    uint256 activeCount = 0;

    // First, count how many are active
    for (uint256 i = 0; i < proposalCount; i++) {
        if (proposals[i].status == ProposalStatus.Active && block.timestamp < proposals[i].votingDeadline) {
            activeCount++;
        }
    }

    Proposal[] memory activeProposals = new Proposal[](activeCount);
    uint256 index = 0;

    // Then, populate the array
    for (uint256 i = 0; i < proposalCount; i++) {
        if (proposals[i].status == ProposalStatus.Active && block.timestamp < proposals[i].votingDeadline) {
            activeProposals[index] = proposals[i];
            index++;
        }
    }

    return activeProposals;
}