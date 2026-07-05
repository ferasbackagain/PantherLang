panther main {
    print "PantherLang Web Server starting...";
    print "Open http://localhost:8080 in your browser";
}

web {
    route GET "/" {
        return "<html><body>"
            + "<h1>Hello from PantherLang Web</h1>"
            + "<p>This is a real HTML page served by PantherLang.</p>"
            + "<form method='POST' action='/submit'>"
            + "  <input name='name' placeholder='Enter your name'>"
            + "  <button type='submit'>Submit</button>"
            + "</form>"
            + "<p><a href='/about'>About</a>"
            + " | <a href='/users/alice'>Path param demo</a></p>"
            + "</body></html>";
    }
    route GET "/about" {
        return "<html><body>"
            + "<h1>About PantherLang</h1>"
            + "<p>Modern, Secure, AI-Native Programming Language</p>"
            + "<p><a href='/'>Home</a></p>"
            + "</body></html>";
    }
    route POST "/submit" {
        return "<html><body>"
            + "<h1>Form Submitted</h1>"
            + "<p>Thank you for submitting the form.</p>"
            + "<p><a href='/'>Back to home</a></p>"
            + "</body></html>";
    }
    route GET "/users/{name}" {
        return "<html><body>"
            + "<h1>User Profile</h1>"
            + "<p>User: " + name + "</p>"
            + "<p><a href='/'>Back to home</a></p>"
            + "</body></html>";
    }
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
