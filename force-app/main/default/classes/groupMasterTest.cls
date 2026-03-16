@IsTest
public class groupMasterTest {
    public static testmethod void runTest() {
        groupMaster gm = new groupMaster();
        gm.isTest = true;
        
        gm.getRoles();
        gm.getProfiles();
        gm.getGroupList();
        gm.clearGroups();
        gm.getOperations();
        gm.getGroupMasterIsCalculating();
        gm.reset();
        
        // Create some new groups
        CollaborationGroup cg = new CollaborationGroup( name = 'groupMaster Test Group', collaborationtype = 'Public' );
        CollaborationGroup cg2 = new CollaborationGroup( name = 'groupMaster Test Group 2', collaborationtype = 'Public' );
        
        insert new CollaborationGroup[] { cg, cg2 };
        
        FeedItem fp = new FeedItem( body = 'test post', parentid = cg.id, createdbyid = userinfo.getuserid() );
        insert fp;
        
        //CollaborationGroupFeed cgf = [select id from CollaborationGroupFeed
        //    where feeditemid = :fp.id];
            
        FeedComment fc = new FeedComment( commentbody = 'test comment', feeditemid = fp.id );
        insert fc;
        
        // Merge
        gm.operation = groupMaster.MERGE_OP;
        gm.getBatchCount();
        gm.sourceGroup = cg.id;
        gm.destGroup = cg2.id;
        
        gm.addGroup();
        
        system.assertEquals( 1, gm.sourceGroups.size() );
        
        gm.IDToRemove = cg.id;
        
        gm.removeGroup();
        
        system.assertEquals( 0, gm.sourceGroups.size() );
        
        gm.addGroup();
        
        Test.startTest();
        gm.launchBatch();
        Test.stopTest();
    }
    
    public static testmethod void runTest2() {
        groupMaster gm = new groupMaster();
        gm.isTest = true;
        
        // Create some new groups
        CollaborationGroup cg = new CollaborationGroup( name = 'groupMaster Test Group', collaborationtype = 'Public' );
        CollaborationGroup cg2 = new CollaborationGroup( name = 'groupMaster Test Group 2', collaborationtype = 'Public' );
        
        insert new CollaborationGroup[] { cg, cg2 };
        
        FeedItem fp = new FeedItem( linkurl = 'http://tradeconnections.corporate.hsbc.com/en/News-and-Opinion/~/media/TradeConnections/Files/Reports-PDF/Global%20Report.ashx', title = 'google', parentid = cg.id, createdbyid = userinfo.getuserid() );
        insert fp;
        
        //CollaborationGroupFeed cgf = [select id from CollaborationGroupFeed
        //    where feedpostid = :fp.id];
            
        FeedComment fc = new FeedComment( commentbody = 'test comment', feeditemid = fp.id );
        insert fc;
        
        // Copy
        gm.reset();
        gm.copySource = cg.id;
        gm.selectedSource();
        
        system.assertNotEquals( null, gm.newName );     
        
        gm.operation = groupMaster.COPY_OP;
        gm.getBatchCount();
        
        Test.startTest();
        gm.launchBatch();
        Test.stopTest();
    }
    
    public static testmethod void runTest3() {
        groupMaster gm = new groupMaster();
        gm.isTest = true;
        
        // Create some new groups
        CollaborationGroup cg = new CollaborationGroup( name = 'groupMaster Test Group', collaborationtype = 'Public' );
        CollaborationGroup cg2 = new CollaborationGroup( name = 'groupMaster Test Group 2', collaborationtype = 'Public' );
        
        insert new CollaborationGroup[] { cg, cg2 };
        
        // Mass add members
        gm.reset();
        
        gm.sourceGroupID = cg2.id;
        gm.sourceRoleID = [select id from UserRole where portaltype = 'None' limit 1].id;
        gm.sourceProfileID = [select id from Profile where usertype = 'Standard' or usertype = 'CSNOnly' limit 1].id;
        
        gm.whichSelect = 1;
        gm.addGRP();
        gm.whichSelect = 2;
        gm.addGRP();
        gm.whichSelect = 3;
        gm.addGRP();
        
        system.assertEquals( 3, gm.memberSources.size() );
        
        gm.IDToRemove = cg2.id;
        gm.removeGRP();
        
        system.assertEquals( 2, gm.memberSources.size() );
        
        gm.destGroupID = cg2.id;
        
        gm.operation = groupMaster.MEMBER_OP;
        gm.getBatchCount();
        
        Test.startTest();
        gm.launchBatch();   
        Test.stopTest();    
    }
}