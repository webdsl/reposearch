module elib/markup 
  
section markup

  template header1(){ <h1> elements </h1> }
  template header2(){ <h2> elements </h2> }
  template header3(){ <h3> elements </h3> }
  template header4(){ <h4> elements </h4> }
  
//  template par() { <p> elements </p> }

section forms

  // define formEntry(l: String){ 
  //   <div class="formentry">
  //     <span class="formentrylabel">output(l)</span>
  //     elements
  //   </div>
  // }
  
  define save() { submit action{ } { "Save" } }
