document.addEventListener('DOMContentLoaded', function() {
    // Fetch server status
    fetch('/api/system')
        .then(r => r.json())
        .then(data => document.getElementById('status').textContent = JSON.stringify(data, null, 2))
        .catch(e => document.getElementById('status').textContent = 'Error: ' + e.message);

    // Echo form
    document.getElementById('echoForm').addEventListener('submit', function(e) {
        e.preventDefault();
        var input = document.getElementById('echoInput').value;
        var result = document.getElementById('echoResult');

        fetch('/api/echo', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({message: input})
        })
        .then(r => r.json())
        .then(data => result.textContent = JSON.stringify(data, null, 2))
        .catch(e => result.textContent = 'Error: ' + e.message);
    });
});
