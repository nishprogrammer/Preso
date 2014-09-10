/**
	Name: Preso_AppHomeController
	Description: Controller for Preso_AppHomePage
	Created By: Sunil Pal (Sep 10th, 2014)
	Last Modified By: Sunil Pal (Sep 10th, 2014)
*/

public with sharing class Preso_AppHomeController {
	
	/**
		Name: PresentationInformation
		Description: Wrapper class for Presentation Information
	*/
	public class PresentationInformation {
		
		public String strPresentationName;
		public Slide__c objSlide;
		public boolean isFavourite;
		
		public PresentationInformation(String strPresentationName, Slide__c objSlide,Favourite_Presentation__c fav) {
			
			this.strPresentationName = strPresentationName;
			this.objSlide = objSlide;
			this.isFavourite = false;
		}
	}
	
	public Preso_AppHomeController() {}	
	
	 /*
		Name 		: 	fetchPresentation
		Description : 	method to fetch all presentation on click of search
		Return Type	: 	List<PresentationInfo>
	*/
	
    @RemoteAction
    public static List<PresentationInformation> fetchPresentation(String keyword, String lauchStatus) {
    	
    	 try {
 			
			Set<Id> presentationId = new Set<Id>();
            
            List<PresentationInformation> lstPresentationInformation;
            
            List<Slide__c> lstSlides = new List<Slide__c>();
            
            Map<Id,Presentation__c> mapIdToPresentation;
            
            Map<Id,PresentationInformation> mapIdToPresentationInformation = new Map<Id,PresentationInformation>();
            
            if(keyword == '') {
                
                mapIdToPresentation = new Map<Id,Presentation__c>([ SELECT Id, Name FROM Presentation__c MRU ]);
                
            }
            if(keyword == 'SORTING') {
                
                if(lauchStatus == 'CREATE')
               		mapIdToPresentation = new Map<Id,Presentation__c>([ SELECT Id, Name FROM Presentation__c ORDER BY CreatedDate ASC  ]);
                if(lauchStatus == 'MODIFY')
               		mapIdToPresentation = new Map<Id,Presentation__c>([ SELECT Id, Name FROM Presentation__c ORDER BY LastModifiedDate ASC  ]);
                
            }
            else if(lauchStatus == 'SEARCH'  && keyword != '') {
                
                keyword = '%' + keyword + '%';
                
                mapIdToPresentation = new Map<Id,Presentation__c>([ SELECT Id, Name FROM Presentation__c WHERE Name like :keyword ]);
            }
            
            for(Slide__c objSlide :     [   SELECT Id, Presentation__c, Presentation__r.Name
                                            FROM Slide__c
                                            WHERE Presentation__c IN : mapIdToPresentation.keyset()
                                            order by Serial_Number__c
                                        ]) {
                 
                if(!presentationId.contains(objSlide.Presentation__c)) { 
                    
                    if(lauchStatus == 'FAVOURITE') {
					
						lstSlides.add(objSlide);
						
						presentationId.add(objSlide.Presentation__c);
						
						for(Favourite_Presentation__c objFav : [  SELECT Related_User__c, Related_Presentation__c
																  FROM Favourite_Presentation__c
																  WHERE Related_Presentation__c= :objSlide.Presentation__c
																  AND Related_User__c =: Userinfo.getUserId()
																]){
																
							if(objFav.Related_Presentation__c != null)	{
								
								mapIdToPresentationInformation.put(objSlide.Presentation__c, new PresentationInformation(objSlide.Presentation__r.Name, objSlide,objFav));
								mapIdToPresentationInformation.get(objFav.Related_Presentation__c).isFavourite = true; 
							}									
						}
					}
				
					else{
						
						mapIdToPresentationInformation.put(objSlide.Presentation__c, new PresentationInformation(objSlide.Presentation__r.Name, objSlide, new Favourite_Presentation__c()));
																 
                    	presentationId.add(objSlide.Presentation__c);
					}
                    
                }
            }
            
            if(lauchStatus != 'FAVOURITE') {
            	
            	for(Favourite_Presentation__c objFav : 	[	SELECT Id, Related_User__c, Related_Presentation__c
	            											FROM Favourite_Presentation__c
	            											WHERE Related_Presentation__c IN : mapIdToPresentationInformation.keyset()
	            											AND Related_User__c =: Userinfo.getUserId()
            											]) {
            											
					mapIdToPresentationInformation.get(objFav.Related_Presentation__c).isFavourite = true; 
				}
            }
            
            system.debug('********* mapIdToPresentationInformation *******'+mapIdToPresentationInformation);
    	 	return mapIdToPresentationInformation.values();
    	 }
    	 catch(Exception e) {
            
            system.debug('## Exception : '+e);
            
            return null;
        }
    }
    
    /*
		Name 		: 	clonePresentation
		Description : 	method to clone the presentation on click of clone
		Return Type	: 	List<Slide__c>
	*/
	
   	@RemoteAction
    public static list<Slide__c> clonePresentation(String strPresentationId) {
    	
   		try {
   		
	   		strPresentationId = 'a00o0000002aHap';
	   		
	   		list<Slide__c> lstSlideInsert = new list<Slide__c>();
	   		
	   		Presentation__c objPresentation = 	[	SELECT Id, Name 
		   											FROM Presentation__c
		   											WHERE Id =: strPresentationId 
	   											];
	   											
			Presentation__c objPresentationCopy = objPresentation.clone(false,true);
			
			objPresentationCopy.Template_Id__c = '111111';
			
	   		insert objPresentationCopy;
	   		
	   		list<Slide__c> lstSlideRecord = [	SELECT Id, Name, Presentation__c, Presentation__r.Name
	   											FROM Slide__c
	   											WHERE Presentation__c =: objPresentation.Id
	   										];
	   										
	   		for(Slide__c objSlide : lstSlideRecord) {
	   			
	   			Slide__c objSlideCopy = objSlide.clone(false, true);
	   			
	   			objSlideCopy.Presentation__c = objPresentationCopy.id;
	   			
	   			lstSlideInsert.add(objSlideCopy);
	   			
	   		}
	   		insert lstSlideInsert;
	   		
	   		return lstSlideInsert;	
   		}
	   	catch(Exception e) {
	            
	            system.debug('## Exception : '+e);
	            
	            return null;
	    }
   	}
   
   	/*
		Name 		: 	addToFavourite
		Description : 	method to make record as favourite on click of favourite icon
		Return Type	: 	Boolean
	*/
	
   	@RemoteAction
    public static Boolean addToFavourite(String strPresentationId, String strActionType) { 
    	
    	try {
    		
    		strPresentationId = 'a00o0000002beIc';
    		Boolean isFavourite = false;
    		
    		List<Favourite_Presentation__c> lstFavouritePresentation = new List<Favourite_Presentation__c>();
    	
    		if(strActionType == 'ADDUNFAV') {
    			
    			lstFavouritePresentation = 	[	SELECT Id
											FROM Favourite_Presentation__c
											WHERE Related_Presentation__c = : strPresentationId 
											AND Related_User__c =: Userinfo.getUserId() 
										];
											
				if(!lstFavouritePresentation.isEmpty()) {
					
					delete lstFavouritePresentation;
				}	
    		}
	    	else if(strActionType == 'ADDFAV' ) {
	    		
	    		insert new Favourite_Presentation__c (	Related_Presentation__c = strPresentationId,
														Related_User__c = Userinfo.getUserId());
														
				isFavourite = true;
	    	}
			
			return isFavourite;
    		
    	}
    	catch(Exception e) {
            
            system.debug('## Exception : '+e);
            
            return null;
        }
    }
   
}