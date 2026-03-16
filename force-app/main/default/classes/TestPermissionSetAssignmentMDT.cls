public class TestPermissionSetAssignmentMDT {

	public static void updatePermissionSet(Boolean removePermissison) {

		boolean haveTestData = false;

		//get list of permission set metadata
		List<PermissionSetAssigment__mdt> perMDTs = PermissionSetAssignmentMDTSelector.newInstance().selectBySourceObj('User');

		//get our list of test users
		List<User> users = UserSelector.newInstance().selectAll();

		//get list of available permission sets
		List<PermissionSet> perms = PermissionSetSelector.newInstance().selectAll();

		//get list of fields on User object
		Map<String, Schema.SObjectField> objFields = User.SObjectType.getDescribe().fields.getMap();

		Set<String> permSet = new Set<String>();
		for(PermissionSet s : perms){
			permSet.add(s.Name);
		}

		//do we have all the collections populated so we can continue
		if(perMDTs.size() > 0 && users.size() > 0 && perms.size() > 0) {

			//find matching records to use
			PermissionSetAssigment__mdt mdt = null;
			String selectedPermisison = '';
			User userToUpdate = null;
			String fieldName = '';

			//flag to get us out of our loop
			Boolean foundRecord = false;

			for(PermissionSetAssigment__mdt m : perMDTs){
				if(foundRecord) break;

				//check to makje sure the field exists on the User object and the Permission set exists
				if(objFields.containsKey(m.Field__r.APIName__c) && permSet.contains(m.PermissionSet__c)){
					
					for(User u : users){
						if(!foundRecord){
							//find a user with/without this permission depending on the removePermissison value
							if((Boolean)u.get(m.Field__r.APIName__c) == removePermissison){
								//we have found our records
								mdt = m;
								selectedPermisison = m.PermissionSet__c;
								fieldName = m.Field__r.APIName__c;
								userToUpdate = u;
								foundRecord = true;
								break;
							}
						}
					}

				}
			}

			//we have our user record so we are good to continue
			if(userToUpdate != null){
				haveTestData = true;

				userToUpdate.put(fieldName, !removePermissison);
				Id userId = userToUpdate.Id;

				update userToUpdate;

				//get user permissionset assignments
				List<PermissionSetAssignment> userPerms = PermissionSetAssignmentSelector.newInstance().selectByUserId(new Set<Id>{userId});
				Set<String> userPermSet = new Set<String>();
				for(PermissionSetAssignment a : userPerms){
					userPermSet.add(a.PermissionSet.Name);
				}

				if(removePermissison){
					System.assert(!userPermSet.contains(selectedPermisison));
				}
				else{
					System.assert(userPermSet.contains(selectedPermisison));
				}

			}
			
			//we didn't have data so return a failed test
			if(!haveTestData) System.assert(false, 'Missing Test Data');
		}
	}
}