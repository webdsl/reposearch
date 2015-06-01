module tools/tools


access control rules
rule page formattool(){ true }
rule ajaxtemplate codearea(formatted : String){ true }


section pages

native class org.webdsl.reposearch.tools.CodeFormatter as CodeFormatter{
	static format(String, Bool, Bool, String) : String
}

page formattool(){
	var whiteSpaceBeforeOpen := false
	var openOnNewLine := false
	var code : Text
	var useSpaces := true
	var twoSpaces := true
	
	action updateCodeArea(){
		var indentChars := if(useSpaces) (if(twoSpaces) "  " else "    ") else "\t";
		replace(formattedCode, codearea(CodeFormatter.format(code,openOnNewLine,whiteSpaceBeforeOpen,indentChars)));
	}
	
	mainResponsive( "Projects" ){
		prettifyCode()
		horizontalForm{
			controlGroup("Options"){
				input(whiteSpaceBeforeOpen)[onchange:=updateCodeArea()]{ " Prefix open curly with white space" }<br />
				input(openOnNewLine)[onchange:=updateCodeArea()]{ " Put open curly on new line" }<br/>
				input(useSpaces)[onchange:=updateCodeArea()]{ " Use spaces instead of tabs" }<br/>
				input(twoSpaces)[onchange:=updateCodeArea()]{ " Use 2 instead of 4 spaces (when using spaces)" }<br/>
			}
			controlGroup("Code"){
				input(code)[oninput:=updateCodeArea(), onclick="this.select();"]
			}
		}
		gridRow{gridCol(12){
			header4{"Formatted"}
			placeholder formattedCode{}
		}}
	}
}

ajax template codearea(formatted : String){
	var inp := (formatted as Text)
	gridRow{
		gridCol(6){
			<div id="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre"> output( formatted ) </pre></div>
			prettifyCodeHelper("",false)
		}		
		gridCol(6){
			input(inp)[onclick="this.select();", id="code-area-input"]
		}
		<script>
			$('#code-area-input').css('min-height', $('#code-area').height() )
		</script>
	}
}
