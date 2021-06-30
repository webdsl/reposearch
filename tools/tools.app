module tools/tools

imports built-in
imports reposearch
imports search/search-misc

imports elib/elib-bootstrap/lib
imports elib/elib-utils/markup

access control rules
rule page indentTool(){ true }
rule ajaxtemplate codearea(formatted : String){ true }


section pages

native class org.webdsl.reposearch.tools.CodeFormatter as CodeFormatter{
	static format(String, Bool, Bool, String) : String
}


enum Indentation{
	TwoSpaces("2 spaces"),
	FourSpaces("4 spaces"),
	OneTab("Tab")
}

page indentTool(){
	var whiteSpaceBeforeOpen := false
	var openOnNewLine := false
	var code : Text
	var indentType := TwoSpaces
	
	action updateCodeArea(){
		var indentChars := if(indentType == TwoSpaces) "  " else (if(indentType == FourSpaces) "    " else "\t");
		replace(formattedCode, codearea(CodeFormatter.format(code,openOnNewLine,whiteSpaceBeforeOpen,indentChars)));
	}
	title{"Indentation Tool | Reposearch"}
	
	mainResponsive( "Projects" ){
		prettifyCode()
		horizontalForm{
			controlGroup("Options"){
				input(whiteSpaceBeforeOpen)[onchange:=updateCodeArea()]{ " Prefix open curly with white space" }<br />
				input(openOnNewLine)[onchange:=updateCodeArea()]{ " Put open curly on new line" }<br/>
				// input(useSpaces)[onchange:=updateCodeArea()]{ " Use spaces instead of tabs" }<br/>
				// input(twoSpaces)
				input(indentType, from Indentation order by name)[onchange:=updateCodeArea()]{ " Use 2 instead of 4 spaces (when using spaces)" }
			}
			controlGroup("Code"){
				input(code)[oninput:=updateCodeArea(), onclick="this.select();"]
			}
		}
		gridRow{gridCol(12){
			placeholder formattedCode{}
		}}
	}
}

ajax template codearea(formatted : String){
	var inp := (formatted as Text)
	gridRow{
		gridCol(6){
			header4{"Indented"}
			<div id="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre"> output( formatted ) </pre></div>
			prettifyCodeHelper("",false)
		}		
		gridCol(6){
			header4{"Copy it!"}
			input(inp)[onclick="this.select();", id="code-area-input", wrap="off"]
		}
		<script>
			$('#code-area-input').css('min-height', $('#code-area').height() )
		</script>
	}
}
