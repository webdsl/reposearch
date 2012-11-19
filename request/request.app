module request/request

section entities

  entity Request {
    project     :: String
    svn         :: URL
    isGithubTag :: Bool
    submitter   :: Email
  }

section pages/templates

  define nOfPendingRequests() {
      var cnt := select count(r) from Request as r;
      if(cnt < 1){ "no requests pending"}
      else       { output(cnt) " pending request(s)" }
  }

  define addProject(){
    <div id="addProject" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
      placeholder addProjectPH addProjectModal()
    </div>
  }

  define ajax addProjectModal(){
    var p    := "";
    var gu   := "";
    var gr   := "";
    var path := "trunk";
    var tag  := false;
    var n : URL := "";
    var submitter : Email := "";
    var r : Request := Request{};



        modalHeader{"Add your project/repository!"}
        form{
          <div class="modal-body">
            controlGroup("Your email (hidden)") {  input(submitter) validate(validateEmail(submitter), "please enter a valid email address") }
            controlGroup("Project name"){     input(p) validate(/[A-Za-z0-9][A-Za-z0-9\-_\.\s]{2,}/.match(p), "Project name should be at least 3 characters (allowed chars: a-z,A-Z,0-9,-,_, ,.)")}
            controlGroup("SVN or Github URL"){ input(n) validate( (n.length() > 6), "please fill in a SVN or Github repository" )}
            controlGroup("This URL is/resides within a github tag"){  input(tag){"this is a location within a tag on Github."} }
            controlGroup("Example links:"){ <i>"http://some.svn.url/repo/trunk"
                            <br />"https://github.com/hibernate/hibernate-search (master branch)"
                            <br />"https://github.com/hibernate/hibernate-search/tree/4.0 (4.0 branch)"
                            <br />"https://github.com/hibernate/hibernate-search/tree/4.0.0.Final (4.0.0.Final tag)"
                            <br />"https://github.com/mobl/mobl-lib/blob/v0.5.0/mobl/ui/generic/touchscroll.js (a file within v0.5.0 tag)"
                          </i>}
         </div>
         <div class="modal-footer">
           submit action{
             r.project:=p; r.svn:=n; r.submitter:=submitter; r.isGithubTag:=tag; r.save();
             newSuccessMessage("Your request is sent to the administrators. You will receive an email when your request is processed");
             emailRequest(r);
           }[class="btn btn-primary"] {"add request"}
         </div>
         }
  }



  define ignore-access-control ajax successMessage(msg : String){
      alertSuccess{ output(msg) }
  }


  define email submitterRequestMail(r:Request, added : Bool, reason : Text) {
    to(r.submitter)
    from("noreply@webdsl.org")
    if (added){ subject("Reposearch request accepted") } else { subject("Reposearch request rejected") }
    par { "Dear recipient," }
    par { "Your request to add the following repository to Reposearch has been "
      if(added){"accepted and should be available for search shortly."}
      else{ "rejected." <br/><br/> "Reason: " output(reason) }
    }
    <br />
    par { "Project: " output(r.project) }
    par { "SVN: " output(r.svn) }
    par { "Github tag?: " output(r.isGithubTag) }
    <br />
    par { navigate(root()){"Go to reposearch"} }
  }

  define email adminRequestMail(to:String,from:String, r : Request) {
    to(to)
    from(from)
    subject("New reposearch repository request")
    par { "A new request is added on reposearch" }
    par { "Requester: " output(r.submitter) }
    par { "Project: " output(r.project) }
    par { "SVN: " output(r.svn) }
    par { "Github tag?: " output(r.isGithubTag) }
    par { navigate(manage()){"Go to manage page"} }
  }

  define page pendingRequests(){
    var pendingRequests := from Request order by project;
    mainResponsive("Projects", "Pending requests"){
        title { "Pending requests - Reposearch" }
        if (pendingRequests.length < 1){"There are no pending requests at this moment." <br />}
        for(r : Request in pendingRequests){
          div[class="top-container-green"]{ output(r.project) " (project name)"}
          div[class="main-container"]{
              list{
                listitem{"SVN: '" output(r.svn) "'"}
                listitem{"is a Github tag: '" output(r.isGithubTag) "'"}
            }
          }
        }
    }
  }


section functions

  function newSuccessMessage(msg : String){
      append("notificationsPH", successMessage(msg));
  }

  function validateEmail(mail : String) : Bool {
    return /([a-zA-Z0-9_\-\.])+@(([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(([a-zA-Z0-9\-]+\.)+)([a-zA-Z]{2,4}))/.match(mail);
  }

  function emailRequest(r : Request){
    var emails : List<Text> := manager.adminEmails.split(",");
    for(e : Text in emails where validateEmail(e)){
      email adminRequestMail(e, "noreply@webdsl.org", r);
    }
  }

  function sendRequestAcceptedMail(r: Request){
      email submitterRequestMail(r, true, "");
  }

  function sendRequestRejectedMail(r: Request, reason : Text){
      email submitterRequestMail(r, false, reason);
  }


