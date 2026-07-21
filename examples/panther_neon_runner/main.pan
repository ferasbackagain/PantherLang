panther main {
    print "==================================================";
    print "     PANTHER NEON RUNNER";
    print "     Built with PantherLang Games SDK";
    print "==================================================";
    print "Server: http://127.0.0.1:8080";
    print "Bridge: ?http=http://127.0.0.1:8080/frame";
    print "";

    // Generate initial stars
    fn gen_stars(count) {
        let result = [];
        let i = 0;
        while i < count {
            result = array_push(result, {x: panther_math_random() * 800, y: panther_math_random() * 600, r: 0.5 + panther_math_random() * 1.5, speed: 0.2 + panther_math_random() * 0.5});
            i = i + 1;
        }
        return result;
    }

    // Pre-seed game state into storage
    let init_store = storage_open("/tmp/panther_neon_runner.db");
    let init_stars = gen_stars(40);
    storage_put(init_store, "state", json_stringify({
        player: {x: 80, y: 400, w: 32, h: 40, vy: 0, grounded: true, score: 0, high_score: 0, game_over: false},
        obstacles: [], stars: init_stars, frame: 0, spawn_timer: 0, input_queue: [], high_score: 0
    }));
    print "State initialized with " + to_string(len(init_stars)) + " stars.";
}

web {
    route GET "/" {
        return "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'>"
            + "<title>Panther Neon Runner</title>"
            + "<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0f19;display:flex;justify-content:center;align-items:center;height:100vh;font-family:monospace;overflow:hidden}"
            + "#gc{position:relative;width:800px;height:600px;border:1px solid #1a2a4a}#cv{display:block;width:100%;height:100%;background:#0a0f19}"
            + "#ol{position:absolute;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column;justify-content:center;align-items:center;pointer-events:none;z-index:10}"
            + "#ol h1{color:#0ff;font-size:36px;text-shadow:0 0 20px #0ff;margin:0}#ol p{color:#8af;font-size:16px;margin-top:12px}#ol .s{color:#468;font-size:12px;margin-top:8px}"
            + "#fps{position:absolute;top:8px;right:8px;color:#0af;font-size:11px;opacity:0.7;pointer-events:none}"
            + "</style></head><body>"
            + "<div id='gc'><canvas id='cv' width='800' height='600'></canvas>"
            + "<div id='ol'><h1>NEON RUNNER</h1><p>Press SPACE to jump &middot; R to restart</p><p class='s'>Loading...</p></div>"
            + "<div id='fps'>-- FPS</div></div>"
            + "<script>"
            + "let cv=document.getElementById('cv'),cx=cv.getContext('2d'),fp=document.getElementById('fps'),ol=document.getElementById('ol');"
            + "let ib=[],lt=performance.now(),fc=0,ft=0,cf=0;"
            + "document.addEventListener('keydown',e=>{ib.push({t:'keydown',k:e.code});if(['Space','ArrowUp','KeyW','KeyR'].includes(e.code))e.preventDefault()});"
            + "document.addEventListener('keyup',e=>{ib.push({t:'keyup',k:e.code})});"
            + "function cl(c){return c?'rgba('+Math.round(c.r*255)+','+Math.round(c.g*255)+','+Math.round(c.b*255)+','+(c.a||1)+')':'transparent'}"
            + "async function po(){try{"
            + "if(ib.length>0){let b=ib.splice(0,ib.length);await fetch('/in',{method:'POST',body:JSON.stringify(b),headers:{'Content-Type':'application/json'}})}"
            + "let r=await fetch('/frame');let f=await r.json();"
            + "if(!f||!f.cmds){setTimeout(po,100);return}"
            + "for(let c of(f.cmds)){switch(c.t){"
            + "case'c':cx.fillStyle=cl(c);cx.fillRect(0,0,800,600);break;"
            + "case'r':cx.fillStyle=cl(c.f);cx.fillRect(c.x,c.y,c.w,c.h);break;"
            + "case'o':cx.fillStyle=cl(c.f);cx.beginPath();cx.arc(c.x,c.y,c.r,0,Math.PI*2);cx.fill();break;"
            + "case't':cx.fillStyle=cl(c.f);cx.font=(c.s||16)+'px monospace';cx.textBaseline='top';cx.fillText(c.t||'',c.x,c.y);break;"
            + "case'l':cx.strokeStyle=cl(c.f);cx.lineWidth=c.w||1;cx.beginPath();cx.moveTo(c.x1,c.y1);cx.lineTo(c.x2,c.y2);cx.stroke();break;"
            + "}}"
            + "let oh=ol.querySelector('h1'),op=ol.querySelector('p'),os=ol.querySelector('.s');"
            + "if(f.go){oh.textContent='GAME OVER';op.textContent='Score: '+f.s+' | Best: '+f.hs;os.textContent='Press R to reset';ol.style.display='flex'}"
            + "else{ol.style.display='none'}"
            + "fc++;let n=performance.now(),e=(n-lt)/1000;ft+=e;if(ft>=1){cf=Math.round(fc/ft);fp.textContent=cf+' FPS';fc=0;ft=0}lt=n"
            + "}catch(ex){setTimeout(po,200);return}setTimeout(po,16)}"
            + "po();"
            + "</script></body></html>";
    }

    route GET "/frame" {
        let store = storage_open("/tmp/panther_neon_runner.db");
        let raw = storage_get(store, "state");
        let s = json_parse(raw);
        if s == null { return {w: 800, h: 600, cmds: [{t: "c", r: 0.08, g: 0.1, b: 0.18, a: 1}], s: 0, hs: 0, go: false}; }

        let p = s.player;
        let obs = s.obstacles;
        let stars = s.stars;
        let frame = s.frame;
        let spawn_timer = s.spawn_timer;
        let ground_y = 440;

        // Physics
        let new_vy = p.vy + 980 * 0.016;
        let new_y = p.y + new_vy * 0.016;
        let grounded = false;
        if new_y + p.h >= ground_y { new_y = ground_y - p.h; new_vy = 0; grounded = true; }

        // Input processing
        let iq = s.input_queue;
        let qi = 0;
        while qi < len(iq) {
            let evt = iq[qi];
            if evt.t == "keydown" {
                let k = evt.k;
                if k == "Space" { if grounded { new_vy = -420; grounded = false; } }
                if k == "ArrowUp" { if grounded { new_vy = -420; grounded = false; } }
                if k == "KeyW" { if grounded { new_vy = -420; grounded = false; } }
            }
            qi = qi + 1;
        }

        // Extract state variables
        let game_over = p.game_over;
        let score = p.score;
        let high_score = s.high_score;

        // Rebuild player after physics/input
        p = {x: p.x, y: new_y, w: p.w, h: p.h, vy: new_vy, grounded: grounded, score: score, high_score: high_score, game_over: game_over};

        // Obstacle spawning (only when not game over)
        if !game_over {
            let si_val = 80 - score / 100;
            if si_val < 20 { si_val = 20; }
            spawn_timer = spawn_timer + 1;
            if spawn_timer >= si_val {
                spawn_timer = 0;
                let oh_val = 20 + panther_math_random() * 30;
                let ow_val = 12 + panther_math_random() * 12;
                obs = array_push(obs, {x: 800, y: ground_y - oh_val, w: ow_val, h: oh_val, speed: 250 + score / 50});
                score = score + 1;
            }
        }

        let new_obs = [];
        let oi = 0;
        while oi < len(obs) {
            let ob = obs[oi];
            let ox = ob.x - ob.speed * 0.016;
            if ox + ob.w > 0 {
                new_obs = array_push(new_obs, {x: ox, y: ob.y, w: ob.w, h: ob.h, speed: ob.speed});
                if !game_over {
                    if panther_game_collision_aabb(p.x, p.y, p.w, p.h, ox, ob.y, ob.w, ob.h) {
                        game_over = true;
                    }
                }
            }
            oi = oi + 1;
        }

        // Star scrolling and rendering
        let new_stars = [];
        let si = 0;
        while si < len(stars) {
            let star = stars[si];
            let sx = star.x - star.speed;
            let sy_val = star.y;
            if sx < 0 { sx = 800; sy_val = panther_math_random() * 600; }
            new_stars = array_push(new_stars, {x: sx, y: sy_val, r: star.r, speed: star.speed});
            si = si + 1;
        }

        let cmds = [{t: "c", r: 0.08, g: 0.1, b: 0.18, a: 1}];
        let si2 = 0;
        while si2 < len(new_stars) {
            let star2 = new_stars[si2];
            cmds = array_push(cmds, {t: "o", x: star2.x, y: star2.y, r: star2.r, f: {r: 0.5 + star2.r * 0.3, g: 0.6 + star2.r * 0.3, b: 1, a: 0.4 + star2.r * 0.3}});
            si2 = si2 + 1;
        }

        cmds = array_push(cmds, {t: "r", x: 0, y: ground_y, w: 800, h: 160, f: {r: 0.12, g: 0.15, b: 0.25, a: 1}});
        let gx = (frame * 3) % 40;
        let gi = 0;
        while gi < 21 {
            cmds = array_push(cmds, {t: "l", x1: gx + gi * 40, y1: ground_y, x2: gx + gi * 40, y2: 600, f: {r: 0.15, g: 0.2, b: 0.35, a: 0.3}, w: 1});
            gi = gi + 1;
        }

        if game_over {
            cmds = array_push(cmds, {t: "r", x: 0, y: 0, w: 800, h: 600, f: {r: 0, g: 0, b: 0, a: 0.5}});
        }
        cmds = array_push(cmds, {t: "r", x: p.x - 3, y: p.y - 3, w: p.w + 6, h: p.h + 6, f: {r: 0, g: 1, b: 1, a: 0.15}});
        cmds = array_push(cmds, {t: "r", x: p.x, y: p.y, w: p.w, h: p.h, f: {r: 0, g: 0.9, b: 1, a: 0.9}});
        cmds = array_push(cmds, {t: "r", x: p.x + 12, y: p.y + 4, w: 8, h: 8, f: {r: 1, g: 1, b: 1, a: 0.9}});
        cmds = array_push(cmds, {t: "t", t: "SCORE: " + to_string(score), x: 16, y: 16, f: {r: 0.5, g: 0.8, b: 1, a: 0.8}, s: 20});
        cmds = array_push(cmds, {t: "t", t: "BEST: " + to_string(high_score), x: 16, y: 40, f: {r: 0.3, g: 0.5, b: 0.8, a: 0.5}, s: 14});

        if score > high_score { high_score = score; }

        p = {x: p.x, y: p.y, w: p.w, h: p.h, vy: p.vy, grounded: p.grounded, score: score, high_score: high_score, game_over: game_over};

        storage_put(store, "state", json_stringify({
            player: p, obstacles: new_obs, stars: new_stars,
            frame: frame + 1, spawn_timer: spawn_timer,
            input_queue: [], high_score: high_score
        }));

        return {w: 800, h: 600, cmds: cmds, s: score, hs: high_score, go: game_over};
    }

    route POST "/in" {
        let store = storage_open("/tmp/panther_neon_runner.db");
        let raw = storage_get(store, "state");
        let s = json_parse(raw);
        if s == null { return {ok: false}; }
        let events = json_parse(req.body);
        if events == null { return {ok: false}; }

        let existing = s.input_queue;
        if existing == null { existing = []; }
        let ei = 0;
        while ei < len(events) {
            existing = array_push(existing, events[ei]);
            ei = ei + 1;
        }

        storage_put(store, "state", json_stringify({
            player: s.player, obstacles: s.obstacles, stars: s.stars,
            frame: s.frame, spawn_timer: s.spawn_timer,
            input_queue: existing, high_score: s.high_score
        }));
        return {ok: true, count: len(events)};
    }

    route GET "/reset" {
        let store = storage_open("/tmp/panther_neon_runner.db");
        let raw = storage_get(store, "state");
        let s = json_parse(raw);
        let hs = 0;
        if s != null { hs = s.high_score; }

        let rst = [];
        if s != null && s.stars != null { rst = s.stars; }
        if len(rst) == 0 {
            let ri = 0;
            while ri < 40 {
                rst = array_push(rst, {x: panther_math_random() * 800, y: panther_math_random() * 600, r: 0.5 + panther_math_random() * 1.5, speed: 0.2 + panther_math_random() * 0.5});
                ri = ri + 1;
            }
        }

        storage_put(store, "state", json_stringify({
            player: {x: 80, y: 400, w: 32, h: 40, vy: 0, grounded: true, score: 0, high_score: hs, game_over: false},
            obstacles: [], stars: rst, frame: 0, spawn_timer: 0, input_queue: [], high_score: hs
        }));
        return {ok: true, high_score: hs};
    }
}
