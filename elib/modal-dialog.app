module elib/modal-dialog

  define modalDialogPopup(context: String) {
    action close() { replace(context+"", empty); }
    <div class="modalDialogBG">
      <div class="modalDialog">
         block[class="modalDialogClose"]{ 
           submitlink close() { "[close]" }
         }
         elements
      </div>
    </div>
  }
  
  

  
