// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract myDAO is Ownable{
 IERC20 private _token;

 struct proposal{
    address proposalOwner;
    uint256 pid;
    string title;
    string des;
    bool decision;
    bool active;
    uint256 duration;
    uint256 voteForCounter;
    uint256 totalVotes;
    uint256 minAmountForVote;
 }



    constructor(address tokenAddress)  Ownable(msg.sender){
        _token = IERC20(tokenAddress);
    }

//  proposal[] public proposals;
 mapping(uint256=>proposal) proposals; 
 mapping(uint256 => address[]) voters;
 mapping(uint256 => mapping(address => bool)) private hasVoted;
 mapping(uint256 => mapping(address => bool)) private votedFor;  
 uint256 private proposalCounter;


function createProposal(string memory title, string memory des, uint256 minAmountForVote, uint256 duration) public {
    require(_token.balanceOf(msg.sender) > 100, "Not Enough balance to create a proposal."); 
    
    uint256 pid = proposalCounter++;
    
    proposal memory prop; 
    prop.proposalOwner = msg.sender;
    prop.pid = pid;
    prop.title = title;
    prop.des = des;
    prop.decision = false;
    prop.active = true;
    prop.duration = block.timestamp + duration;
    prop.minAmountForVote = minAmountForVote;
    proposals[pid] = prop; 
}


modifier validateExpiry(uint256 id){
        
       if(block.timestamp > proposals[id].duration)
       {
        proposals[id].active = false;
       }
        _;
    }

function casteVote(uint256 pid, bool voteFor) public validateExpiry(pid) {
    proposal storage prop = proposals[pid];
    require(prop.active, "The proposal is not active yet");
    require(msg.sender != owner(), "Owner of the proposal cannot place vote.");
    require(_token.balanceOf(msg.sender) >= prop.minAmountForVote, "Not Enough balance to place vote.");
    require(!hasVoted[pid][msg.sender], "You have already voted on this proposal.");

    if (voteFor) {
        prop.voteForCounter++;
        votedFor[pid][msg.sender] = true; 
    } else {
        votedFor[pid][msg.sender] = false; 
    }
    
    prop.totalVotes++;
    hasVoted[pid][msg.sender] = true;
    voters[pid].push(msg.sender);
}



function withdrawVote(uint256 pid) public validateExpiry(pid) {
    require(hasVoted[pid][msg.sender], "You have no votes for the corresponding ID or the ID doesn't exist.");
    require(proposals[pid].active, "You cannot withdraw vote after proposal has expired.");

    
    if (votedFor[pid][msg.sender]) {
        if (proposals[pid].voteForCounter > 0) {
            proposals[pid].voteForCounter--;
        }
    }

    if (proposals[pid].totalVotes > 0) {
        proposals[pid].totalVotes--;
    }
    hasVoted[pid][msg.sender] = false;
    votedFor[pid][msg.sender] = false; 
}

function calculateDecision(uint256 pid) internal returns(bool){
    if(proposals[pid].voteForCounter > (proposals[pid].totalVotes)/2){
        proposals[pid].decision = true;
        return true;
    }

} 

function executeResult(uint256 pid) validateExpiry(pid) public{
    require(msg.sender == proposals[pid].proposalOwner, "Only the Owner of the Proposal can execute the Decision");
    require(!proposals[pid].active, "The Proposal is still ongoing. Cannot implement decision now");
    require(calculateDecision(pid), "Majority has decided against the proposal!");
}

function getProposalCount() public view returns (uint256) {
    return proposalCounter;
}

function getProposal(uint256 pid) public view returns (
    address proposalOwner,
    uint256 id,
    string memory title,
    string memory des,
    bool decision,
    bool active,
    uint256 duration,
    uint256 voteForCounter,
    uint256 totalVotes
) {
    proposal memory prop = proposals[pid];
    return (
        prop.proposalOwner,
        prop.pid,
        prop.title,
        prop.des,
        prop.decision,
        prop.active,
        prop.duration,
        prop.voteForCounter,
        prop.totalVotes
    );
}

function getProposalOwner(uint256 pid) public view returns (address) {
    return proposals[pid].proposalOwner;
}

function isProposalActive(uint256 pid) public view returns (bool) {
    return proposals[pid].active;
}

function getTotalVotes(uint256 pid) public view returns (uint256) {
    return proposals[pid].totalVotes;
}
function getVotesFor(uint256 pid) public view returns (uint256) {
    return proposals[pid].voteForCounter;
}
function getProposalDecision(uint256 pid) public view returns (bool) {
    return proposals[pid].decision;
}
function getVoters(uint256 pid) public view returns (address[] memory) {
    return voters[pid];
}


}