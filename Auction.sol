// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 ;

contract auction{

    address payable public owner ; 
    uint256 public start ;
    uint256 public end ; 
    string public ipfshash ; 
    
    enum state {start , running , stop , cancel}
    state public auction_state ; 
    
    uint256 public highestbid ; 
    address payable public highest_bidder ;
    
    mapping (address => uint256) public bids ; 
    
    uint256 bidincrement ; 
   // event transfer(address _recepient ,uint256 _vlaue ); 
    //event BidPlaced(address indexed bidder, uint256 _value); 

    constructor(){
        owner =payable(msg.sender); 
        auction_state = state.running ; 
        start = block.number ; 
        end = start + 4 ;
        ipfshash = "";
        bidincrement = 1000000000000000000; 
        }

    modifier not_owner(){
        require(msg.sender!=owner);
        _;
    }
    modifier only_owner(){
        require(msg.sender == owner);
        _;
    }
    modifier after_start(){
        require(block.number >= start);
        _;
    }
    modifier before_end(){
        require(block.number <= end);
        _;
    }
    function cancel () public only_owner {
        auction_state = state.cancel ; 
    }
    function min (uint256 a ,uint256 b) internal pure returns (uint256){
        if(a <= b){
            return a ;
        }else{
            return b ;
        }
    }
    function bid() public payable not_owner after_start before_end {
        require(auction_state == state.running) ; 
        require(msg.value >= 100);
        uint256 current_bid ; 
        current_bid = bids[msg.sender] + msg.value; 
        require(current_bid > highestbid );
        bids[msg.sender]  = current_bid ; 
        if (current_bid<=bids[highest_bidder]){
            highestbid = min(current_bid + bidincrement  , bids[highest_bidder]);
        }else{
            highestbid = min(current_bid , bids[highest_bidder] + bidincrement) ; 
            highest_bidder = payable (msg.sender) ;
        }
        //emit BidPlaced(msg.sender , msg.value);
    }
    function finalize() public  {
        require(block.number > end || auction_state == state.cancel) ; 
        require(msg.sender == owner || bids[msg.sender] > 0 ) ;
        
        address payable recipient;
        uint256 value ;
        if(auction_state == state.cancel){ //if auction canceled 
            recipient = payable (msg.sender); 
            value = bids[msg.sender] ; 
        }else{// if auction ended(not canceled) 
            if(msg.sender == owner ){
                recipient = owner ;
                value = highestbid;
            }else{
                if(msg.sender == highest_bidder){
                    recipient= highest_bidder ; 
                    value = bids[highest_bidder] - highestbid ; 
                }else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender] ; 
                }
            }
        }
        bids[recipient] = 0 ;// this wont let the other bidders whos are not the highest bidder to finalize twice only once
        //emit transfer(recipient ,value );
        recipient.transfer(value);
    }  
    
}