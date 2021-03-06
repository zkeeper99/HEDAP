/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Contacts
* @group-content ../../ApexDocContent/Contacts.htm
* @description Tests Email Management Classes
*/
@isTest
private class CON_Email_TEST {
	
	@testSetup
	static void dataSetup() {

		// Get contacts set up
        List<Contact> listCon = UTIL_UnitTestData_TEST.getMultipleTestContacts(10);
        for (Integer i = 0; i < 10; i++) {

            listCon[i].LastName = 'ToAvoidDupeRule' + i;//Avoid duplicate matching
            listCon[i].WorkEmail__c = ''; // clear email field set in getMultipleTestContacts
            listCon[i].Preferred_Email__c = ''; // clear preferred field set in getMultipleTestContacts
        }

        insert listCon;
	}

	@isTest static void testPrefferedEmailInsert() {
		List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE EMAIL != null LIMIT 2];
		List<String> contIds = new List<String>();

        for (Integer i = 0; i < contacts.size(); i++) {
			contacts[i].Preferred_Email__c = 'Alternate';
			contacts[i].AlternateEmail__c = 'alternetemailtest' + i + '@domainemail.com';
			contIds.add(contacts[i].Id);
        }

		Test.startTest();
        update contacts;
		Test.stopTest();

		contacts = [SELECT Id, Name, AlternateEmail__c, Email FROM Contact WHERE Id in:contIds LIMIT 2];

        if(contacts.size()>0) {
	        for(Contact c : contacts) {
	        	// Make sure the new values were copies to the standard email field
	            System.assertEquals(c.Email, c.AlternateEmail__c);
            }
        }
	}

	@isTest static void testPrefferedEmailDeleting() {

		List<Contact> contacts = [SELECT Id, Name, Preferred_Email__c, Email, AlternateEmail__c,UniversityEmail__c, WorkEmail__c FROM Contact LIMIT 1];

		// Process the contact for testing
        if(contacts.size()>0) {
        	contacts[0].WorkEmail__c = 'testworkemail@domain.com';
        	contacts[0].Preferred_Email__c = 'Work';
		    CON_Preferred_TDTM.alreadyRunBefore = true; // turn off preferred emial processing
	        update contacts;

        	contacts[0].Preferred_Email__c = null;
        	contacts[0].AlternateEmail__c = null;
        	contacts[0].UniversityEmail__c = null;
        	contacts[0].WorkEmail__c = null;
        }

	    CON_Preferred_TDTM.alreadyRunBefore = false; // need to re-activate the trigger

		Test.startTest();
        update contacts;
		Test.stopTest();

		contacts = [SELECT Id, Name, Preferred_Email__c, Email, AlternateEmail__c,UniversityEmail__c, WorkEmail__c FROM Contact WHERE id =: contacts[0].Id LIMIT 1];

		System.assertEquals(null, contacts[0].Email); // Contact email should be null because all other emails fields were deleted.
	}

	// Test the batch Class
	@isTest static void testContactEmailBatch() {
		List<String> contIds = new List<String>();

		List<Contact> contacts = [SELECT Id, Name, Preferred_Email__c, Email, AlternateEmail__c,UniversityEmail__c, WorkEmail__c FROM Contact];

		// Process the contact for testing
        if(contacts.size()>0) {

	        for (Integer i = 0; i < contacts.size(); i++) {
				contacts[i].Email = 'emailtest' + i + '@domainemail.com';
				contIds.add(contacts[i].Id);
	        }

	        CON_Preferred_TDTM.alreadyRunBefore = true; // need to turn off the trigger for this test
	        update contacts;

        	contacts[0].Preferred_Email__c = null;
        	contacts[0].AlternateEmail__c = null;
        	contacts[0].UniversityEmail__c = null;
        	contacts[0].WorkEmail__c = null;
        }

	    CON_Preferred_TDTM.alreadyRunBefore = false; // need to activate these for the batch

		// Run Batch
		Test.startTest();
	    CON_Email_BATCH contbatch = new CON_Email_BATCH();
	    Database.executeBatch( contbatch );
		Test.stopTest();

		// After batch run assert
		contacts = [SELECT Id, Name, Email, AlternateEmail__c FROM Contact WHERE Id in: contIds ];

		for(Contact c : contacts) {
			System.assertEquals( c.AlternateEmail__c , c.Email ); 
		}
	}	
}