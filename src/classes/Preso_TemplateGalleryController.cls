public with sharing class Preso_TemplateGalleryController {

     public String strFetched_templateId                                {get;set;}
    public String strFetched_templateName                               {get;set;}
    
    public List<Template> lstPresentationTemplate         				{get;set;}
    public List<TemplateLayout> lstTemplateLayouts                 		{get;set;}
    public String strHtmlContact                                        {get;set;}
    
    private String valueToShow = '';
    public Preso_TemplateGalleryController() {
        
        //do nothing
         lstPresentationTemplate = new List<Template> ();
         lstTemplateLayouts  = new List<TemplateLayout> (); 
    }   
    
    public class Template
    {
        public String HTMLContent                                       {get;set;}
        public String templateName                                      {get;set;}
        public String strTemplateId                                     {get;set;}
        
        public Template(String HTMLContent, String templateName, String strTemplateId)
        {
            this.HTMLContent = HTMLContent;
            this.templateName = templateName;
            this.strTemplateId = strTemplateId;
            
        } 
    }
    
    public class TemplateLayout {
    
        public String HTMLContentOfTemplateLayout                                {get;set;}
     //   public String templateName_Name                                 {get;set;}
        
        public TemplateLayout(String HTMLContent_Layout)
        {
            this.HTMLContentOfTemplateLayout = HTMLContent_Layout;
           // this.templateName_Name = templateName_Name;
        }
    }
     
    
    @RemoteAction
    public static List<Template> authenticateAndFetchTemplates(List<Template> lstPresentationTemplate) {
   
        String secretCode = createSecretCode();
        HttpRequest req = new HttpRequest();
        // set up the HTTP request with a method, endpoint
        req.setMethod('GET');   
        String templateRequestString = secretCode +','+UserInfo.getOrganizationId()+','+UserInfo.getOrganizationName();     
        req.setEndpoint('http://preso-for-salesforce1.herokuapp.com/fetchTemplates/getTemplates/'+secretCode+'?orgId='+UserInfo.getOrganizationId()+'&orgName='+UserInfo.getOrganizationName());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); 
       // create a new HTTP object
        Http http = new Http();
        // create a new HTTP response for receiving the remote response
        // then use it to send the configured HTTPrequest
        HTTPResponse res = http.send(req);
        //valueToShow = res.getBody();
        lstPresentationTemplate = parseAuthJSON(res.getBody(),lstPresentationTemplate);
        return lstPresentationTemplate;
            
    }
    
    private static string createSecretCode() {
        
        return EncodingUtil.base64Encode(Blob.valueOf('HerokuIntegration secret codessXXXXYY ZZZZZ'));
    }
    
    
    private static List<Template> parseAuthJSON(String JSONValue, List<Template> lstPresentationTemplate) {
       
       string strTempId = '';
       String HTMLContent_Show;
       string templateName_Show ;
     
        Map <String,Template> mapTemplateIdToListOfTsemplates= new Map <String, Template> ();
        JSONParser parser = JSON.createParser(JSONValue);
        
        while (parser.nextToken() != null) {
      
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
            	
            	  if(parser.getText() == 'templateId') {
                    
                    parser.nextToken();
                    strTempId = parser.getText();
                  }
               
                  if(parser.getText() == 'templateName') {
                       
                       parser.nextToken();
                       templateName_Show = parser.getText(); 
                  } 
                  if(parser.getText() == 'content') {
                             
                     parser.nextToken();
                     HTMLContent_Show = parser.getText();
                  }
               
                 if(HTMLContent_Show != null && templateName_Show != null && strTempId != null) {
                    
                    if(HTMLContent_Show.contains('<!DOCTYPE html>')) {
                        
                        HTMLContent_Show = HTMLContent_Show.replace('<!DOCTYPE html>','');
                        HTMLContent_Show = HTMLContent_Show.replace('</html>','');
                        
                        
                        if(HTMLContent_Show.contains('<br>')) {
                        
                            HTMLContent_Show = HTMLContent_Show.replace('<br>', '</br>');
                        }
                        
                        
                      
                    }
                    
                 }
            }
            
           	if(mapTemplateIdToListOfTsemplates.get(strTempId)==null) {
           		if(HTMLContent_Show !='' && templateName_Show!=''&&HTMLContent_Show !=null && templateName_Show!=null) {
           			
           			mapTemplateIdToListOfTsemplates.put(strTempId,new Template(HTMLContent_Show,templateName_Show,strTempId));
           			HTMLContent_Show = null;
           			templateName_Show = null;
           			strTempId = null;
           			
           		}
           }
           		
        }
       // system.debug('++++++++map++++++'+mapTemplateIdToListOfTsemplates);
        lstPresentationTemplate = mapTemplateIdToListOfTsemplates.values();
        return lstPresentationTemplate;
    }
    
     @RemoteAction
     public static List<TemplateLayout> authenticateAndFetchTemplateById (List<TemplateLayout> lstTemplateLayouts, String templateId) { 
   
		String secretCode = createSecretCode();
		
		HttpRequest req = new HttpRequest();
		// set up the HTTP request with a method, endpoint
		req.setMethod('GET');		
		req.setEndpoint('http://preso-for-salesforce1.herokuapp.com/fetchTemplates/getTemplateById/'+secretCode+'?orgId='+UserInfo.getOrganizationId()+'&templateId=' + templateId);
		req.setHeader('Content-Type', 'application/json');
		//req.setBody(jsonTemplateRequest);
		req.setTimeout(120000);
		// create a new HTTP object
		Http http = new Http();
		// create a new HTTP response for receiving the remote response
		// then use it to send the configured HTTPrequest		
		HTTPResponse res = http.send(req);
		lstTemplateLayouts = parseAuthJSONTemplateById(res.getBody(),lstTemplateLayouts);
		return lstTemplateLayouts;
			
    }
    
    private static List<TemplateLayout> parseAuthJSONTemplateById(String JSONValue, List<TemplateLayout> lstTemplateLayouts) {
    
    	String template_Id  = '';
    	String strContent = '';
    	string strTemplateLayoutId;
    	//lstTemplateLayouts = new List<TemplateLayout> ();
    	Map <String,TemplateLayout> mapTemplateLayOutIdToTemplateLayout= new Map <String, TemplateLayout> ();
    	
    	JSONParser parser = JSON.createParser(JSONValue);
        
        while (parser.nextToken() != null) {
      
		    if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
		       
				if(parser.getText() == 'templateId') {
			           
					parser.nextToken();
   					template_Id = parser.getText(); 
   					
				} 
				if(parser.getText() == 'templateLayOutId') {
			                 
	                parser.nextToken();
	                strTemplateLayoutId = parser.getText();
	                
			    }
			    if(parser.getText() == 'htmlContentOfLayout') {
			                 
	                parser.nextToken();
	                strContent = parser.getText();
	                
			    }
			//	if(template_Id != '' && strContent != '' ) {
			      	
			      	if(strContent.contains('<!DOCTYPE html>')) {
			      		
			      		strContent = strContent.replace('<!DOCTYPE html>', '');
			      		strContent = strContent.replace('</html>','');
			      	}	
			      /*	else {
			      		
			      		if(strContent.contains('<br>')) {
			      		
			      			strContent = strContent.replace('<br>', '</br>');
			      		}
			      		if(strContent.contains('\t')) {
			      		
			      			strContent = strContent.replace('\t', '');
			      		}
			      		if(strContent.contains('\"')) {
			      		
			      			strContent = strContent.replace('\"', '"');
			      		}*/
						      		
						
			      //	}		
			   // }
		    }
		    if(mapTemplateLayOutIdToTemplateLayout.get(strTemplateLayoutId)==null) {
							
			       	if(strContent !='' && strTemplateLayoutId!=''&&strContent !=null && strTemplateLayoutId!=null) {
			       			
			       			mapTemplateLayOutIdToTemplateLayout.put(strTemplateLayoutId,new TemplateLayout(strContent));
			       			strContent = null;
			       			strTemplateLayoutId = null;
			       			
			       			
			       		}
       		}
	   	}
	   
					      		
  		//lstTemplateLayouts.add(new TemplateLayout(strContent));
  		system.debug('++++++++map++++++'+mapTemplateLayOutIdToTemplateLayout.values());
	   	lstTemplateLayouts = mapTemplateLayOutIdToTemplateLayout.values();
	   	return lstTemplateLayouts;
    }
   
}