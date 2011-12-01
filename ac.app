module ac

  entity User {
    name :: String
    password :: Secret
  }
  principal is User with credentials name, password


page init(){
  var name : String := "admin";
  var pass : Secret;
  
  	
	if ((from User).length > 0){
		output("The one and only user already exists, your bank account will now be plundered")
	} else{
		form {
		
		  label("Username:"){ input(name) }
		  label("Password:"){ input(pass) }
		
		  submit save() { "save" }
		}
		
	}
	action save(){
	  User{ 
	    name := name 
	    password := pass.digest()
	  }.save();
	  return root();
	}
}

page dologin(){
	authentication()
}

page renewAdmin(){
  var user    := securityContext.principal;
  var newName := user.name;
  var newPass : Secret;
  	
	form {
	
	  label("new username:"){ input(newName) }
	  label("new password:"){ input(newPass) }
	
	  submit save() { "save" }
	}
	action save(){
	  logout();
	  user.name := newName;
	  user.password := newPass.digest();
	  user.save();
	  return root();
	}
}

  access control rules

    rule page root(){true}
    rule page showFile(*){true}
    rule page search(*){true}
    rule page manage(){loggedIn()}    
    rule ajaxtemplate paginatedTemplate(*){true}
	rule ajaxtemplate paginatedResults(*){true}
	rule page skippedFiles(*){true}
	rule page autocompleteService(*){true}
	rule page init(*){true}
	rule page dologin(){true}
	rule page renewAdmin(){loggedIn()}
	rule page doSearch(*){ true }



