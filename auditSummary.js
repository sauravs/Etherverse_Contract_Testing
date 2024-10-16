
 
 *  there is a naming conflict between the Upgrade interface declared in src/nft/lib/Structs.sol and the UpgradeV1 contract imported in test/EtherverseNFT.t.sol
 
 
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
   Project : https://github.com/PrideVelConsulting/GameX-Contracts/tree/dev
   
   Commit ID : https://github.com/PrideVelConsulting/GameX-Contracts/commit/6fedb5ab38d31f58396bbf0c6e8081f3065a419c
   
   
   
    Files In Scope:

    No of lines to audit: 

   

                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 GAS
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////


							  
				GAS-01: Use calldata instead of memory for function arguments that do not get mutated to save gas.
				
				
				 No of Instances: 5
				 
				 Location : 
				 
				 EtherverseNFT.sol : 
				 
				 Line No : 195 function setSign()
				 Line No : 218 function changeImageUrl()
				 Line No : 224 function setMetadata()
				 Line No : 313 function paidUpgrade()
				 
				 
				 
				 UpgradeV1.sol : 
				 
				 Line No : 19 function calculateUpgrade()
        
                
                Explaination and Examples:
				
				Mark data types as calldata instead of memory where possible. This makes it so that the data is not automatically loaded into memory.
				It is generally cheaper to load variables directly from calldata, rather than copying them to memory. Only use memory if the variable needs to be modified.
				
			
				
				For example:  
				
				function SetSign() (gas: 40212) (with calldata)
	            function SetSign() (gas: 40557) (with memory)
				
				Unoptimized Code : 
				function setSign(bytes memory _sign) external onlyOwner {         
                sign = _sign;
                }
				
				Optimized Code : 
				
				function setSign(bytes calldata _sign) external onlyOwner {         
                sign = _sign;
                }
	

                
           
                
              
             
               			 
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  


                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 INFO
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////




							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  

                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 LOW
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////

            L-1: Missing checks for `address(0)` when assigning values to address state variables
			
		 * src/common/EtherverseUser.sol [Line: 42](src/common/EtherverseUser.sol#L42)
		 * src/common/EtherverseUser.sol [Line: 44](src/common/EtherverseUser.sol#L44)
		 * src/common/EtherverseUser.sol [Line: 45](src/common/EtherverseUser.sol#L45)
		 * src/misc/Game.sol [Line: 77](src/misc/Game.sol#L77)
		 * src/misc/Game.sol [Line: 81](src/misc/Game.sol#L81)
		 * src/nft/EtherverseNFT.sol [Line: 152](src/nft/EtherverseNFT.sol#L152)
		 * src/nft/EtherverseNFT.sol [Line: 156](src/nft/EtherverseNFT.sol#L156)
		 * src/nft/EtherverseNFT.sol [Line: 162](src/nft/EtherverseNFT.sol#L162)
		 
		 L-2:  `public` functions not used internally could be marked `external`
		 
		 * src/mock/MockUSDC.sol [Line: 10](src/mock/MockUSDC.sol#L10)
		 * src/nft/EtherverseNFT.sol [Line: 232](src/nft/EtherverseNFT.sol#L232)
		 *  src/nft/EtherverseNFT.sol [Line: 342](src/nft/EtherverseNFT.sol#L342)
		 *  src/nft/EtherverseNFT.sol [Line: 350](src/nft/EtherverseNFT.sol#L350)
		 *
			


							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  

                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 MEDIUM
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////




							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 HIGH
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////


   
 
 
 
 
 
 
 
 
  