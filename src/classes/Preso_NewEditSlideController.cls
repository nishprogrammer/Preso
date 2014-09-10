/**
	Name: Preso_NewEditSlideController
	Description: Controller for New/Edit slide page
	Created By: Nishant Sharma [10th Sept, 2014]
	Last Modified By: Nishant Sharma [10th Sept, 2014]
*/
public with sharing class Preso_NewEditSlideController {
	
	public String strSelectedPresentationId {get;set;}

	/**
		Name: PresentationInfo
		Description: Wrapper class for selected slide and all slide for selected presentation
	*/

	public class PresentationInfo {

		public Slide__c selectedSlide;
		public List<Slide__c> lstSlides;

		public PresentationInfo(Slide__c selectedSlide, List<Slide__c> lstSlides) {

			this.selectedSlide = selectedSlide;
			this.lstSlides = lstSlides;
		}
	}

	/**
		Default Constructor
	*/
	public Preso_NewEditSlideController() {
		
		init();

		try {

			if(	apexpages.currentpage().getparameters().containsKey('presentationId')) {

				strSelectedPresentationId = apexpages.currentpage().getparameters().get('presentationId');

				if(strSelectedPresentationId != '') {

					List<Presentation__c> lstPresentation = new List<Presentation__c>(	[	SELECT Id
																							FROM Presentation__c
																							WHERE Id =: strSelectedPresentationId
																							limit 1
																						]);

					if(lstPresentation.isEmpty()) {

						strSelectedPresentationId = '';
						/*Error handling for invalid presentation id*/
					}
				}
				else {

					/*Error handling for presentation id not specified in URL*/
				}
			}
			else {

				/*Error handling for presentation id not specified in URL*/
			}
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);
		}
	}

	/**
		Name: init
		Description: function to initialize varibales
		Access: private
		Return Type: Void
		Param: none
	*/

	private void init() {

		strSelectedPresentationId = '';
	}

	/**
		Name: fetchAllSlides
		Description: function to fetch all slides
		Access: private
		Return Type: void
		Param: 	1. String presentationId
	*/

	@RemoteAction
	public static List<Slide__c> fetchAllSlides(String presentationId) {

		try {

			List<Slide__c> lstSlides = new List<Slide__c>();

			lstSlides = [	SELECT Id, Content__c
							FROM Slide__c
							WHERE Presentation__c =: presentationId
							order by Serial_Number__c
						];

			return (!lstSlides.isEmpty()) ? lstSlides : null;
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);
			return null;
		}
	}

	/**
		Name: getSlide
		Description: function to fetch selected slide
		Access: public
		Return Type: Slide__c
		Param: 	1. String slideId
	*/

	@RemoteAction
	public static Slide__c getSlide(String slideId) {

		try {

			List<Slide__c> lstSlidesTemp = new List<Slide__c>();

			lstSlidesTemp = [	SELECT Id, Content__c
								FROM Slide__c
								WHERE Id =: slideId
								limit 1
							];

			return (!lstSlidesTemp.isEmpty()) ? lstSlidesTemp[0] : null;
		}
		catch(Exception e) {

			system.debug('## Exception :' + e);
			return null;
		}
	}

	/**
		Name: addNewSlide
		Description: function to add new slide
		Access: public
		Return Type: PresentationInfo
		Param: 	1. String presentationId
				2. String htmlLayout
	*/
	@RemoteAction
	public static PresentationInfo addNewSlide(String presentationId, String htmlLayout) {

		try {

			List<Presentation__c> lstPresentations = new List<Presentation__c>([	SELECT Total_Slides__c
																					FROM Presentation__c
																					WHERE Id =: presentationId
																					limit 1
																				]);

			if(lstPresentations.isEmpty()) return null;

			Slide__c objNewSlide = new Slide__c(	Content__c = htmlLayout,
													Presentation__c = presentationId,
													Serial_Number__c = lstPresentations[0].Total_Slides__c
													);
			
			insert objNewSlide;

			return new PresentationInfo(objNewSlide,fetchAllSlides(presentationId));
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);

			return null;
		}
	}

	/**
		Name: cloneSlide
		Description: function to clone selected slide
		Access: public
		Return Type: PresentationInfo
		Param: 	1. String slideId
	*/
	@RemoteAction
	public static PresentationInfo cloneSlide(String slideId) {

		try {

			Slide__c objNewSlide;
			Slide__c objSlideToClone;

			List<Slide__c> lstSlides = new List<Slide__c>(	[	SELECT Content__c, Presentation__c,
																Presentation__r.Total_Slides__c
																FROM Slide__c
																WHERE Id =: slideId
																limit 1
															]);

			if(lstSlides.isEmpty()) return null;

			objSlideToClone = lstSlides[0];

			objNewSlide = new Slide__c(	Content__c = objSlideToClone.Content__c,
										Presentation__c = objSlideToClone.Presentation__c,
										Serial_Number__c = objSlideToClone.Presentation__r.Total_Slides__c
										);
			
			insert objNewSlide;

			return new PresentationInfo(objNewSlide,fetchAllSlides(String.valueOf(objNewSlide.Presentation__c)));
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);

			return null;
		}
	}

	/**
		Name: deleteSlide
		Description: function to delete selected slide
		Access: public
		Return Type: PresentationInfo
		Param: 	1. String slideId
				2. String presentationId
	*/
	@RemoteAction
	public static PresentationInfo deleteSlide(String slideId, String presentationId) {

		try {

			delete new Slide__c(Id = slideId);

			List<Slide__c> lstSlides = new List<Slide__c>();

			lstSlides.addAll(fetchAllSlides(presentationId));

			return new PresentationInfo(lstSlides[0],lstSlides);
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);

			return null;
		}
	}

	/**
		Name: rearrangeSlides
		Description: function to re-arrange slides
		Access: public
		Return Type: PresentationInfo
		Param:  1. String slideId
				2. String slideIds
	*/
	@RemoteAction
	public static PresentationInfo rearrangeSlides(String slideId, String slideIds) {

		try {

			Integer index = 0;

			List<Slide__c> lstSlides = new List<Slide__c>();
			List<String> lstSlideIds = slideIds.split('#');

			for(String slideIdTemp : lstSlideIds) {

				lstSlides.add(new Slide__c(Id = Id.valueOf(slideIdTemp), Serial_Number__c = index));

				index++;
			}

			update lstSlides;

			lstSlides = new List<Slide__c>(	[	SELECT Id, Content__c, Presentation__c
												FROM Slide__c
												WHERE Id =: slideId
												limit 1
											]);

			return new PresentationInfo(lstSlides[0],fetchAllSlides(String.valueOf(lstSlides[0].Id)));
		}
		catch(Exception e) {

			system.debug('## Exception : '+e);

			return null;
		}
	}
}