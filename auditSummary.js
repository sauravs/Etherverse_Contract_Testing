
 
 *  there is a naming conflict between the Upgrade interface declared in src/nft/lib/Structs.sol and the UpgradeV1 contract imported in test/EtherverseNFT.t.sol
 
 
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
   Project : https://github.com/PrideVelConsulting/GameX-Contracts/tree/dev
   
   Commit ID : https://github.com/PrideVelConsulting/GameX-Contracts/commit/6fedb5ab38d31f58396bbf0c6e8081f3065a419c
   
   
   
    Files In Scope:

    No of lines to audit: 

   

                               ///////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                                 GAS
                              ///////////////////////////////////////////////////////////////////////////////////////////////////////////


							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  
							  


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


   
 
 
 
 
 
 
 
 
  