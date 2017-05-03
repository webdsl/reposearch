/* this allows us to pass in HTML tags to autocomplete. Without this they get escaped */
$[ "ui" ][ "autocomplete" ].prototype["_renderItem"] = function( ul, item) {
return $( "<li></li>" ) 
  .data( "item.autocomplete", item )
  .append( $( "<a></a>" ).html( item.label ) )
  .appendTo( ul );
};

function setupcompletion(url){
  $(function() {
    $( "#searchfield" ).autocomplete({
      autoFocus: false,
      select: function(event, ui) {
        if(ui.item){
            $(this).val(ui.item.value);
            $(this).keyup();
        }
      },
      source: 
        function( request, response ) {
          $.ajax({
            url: contextpath+url+"/"+request.term,
            dataType: "json",
            success: 
              function( data ) {
                response( $.map( data, function( item ) {
                  return {
                    label: 
                      item.replace(
                        new RegExp(
                         "("+ $.ui.autocomplete.escapeRegex(request.term) +")?(.*)", "gi"
                        ), "$1<b>$2</b>" ),
                    value: item
                  }
                }));
              }
          }); 
        },
      minLength: 1,
      delay: 200
    }).keypress(function(event){
      if(event.keyCode === 13){
        event.preventDefault();
        $(event.target).autocomplete( "close" );
      }
    }); 
  });
}
