module elib/request

section remote address

  // usage: output(ThreadLocalServlet.get().getRequest().getRemoteAddr())

  native class utils.ThreadLocalServlet as ThreadLocalServlet {
    static get() : ThreadLocalServlet
    getRequest() : HttpServletRequest
  }
  
  native class javax.servlet.http.HttpServletRequest as HttpServletRequest{
    getRemoteAddr() : String
  }
  
  function remoteAddress(): String {
    return ThreadLocalServlet.get().getRequest().getRemoteAddr();
  }