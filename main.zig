const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("raygui.h");
});

const std = @import("std");

const GameState = enum { Menu, Play };
var game_state = GameState.Menu;

const PlayState = enum {Init, Play, Over};
var play_state = PlayState.Init;

const world_origin: ray.Vector3 = .{ .x = 100, .y = 100, .z = 100 };

const good_answers = [_][*c]const u8{
    "ALMOST THERE",
    "TRAFFIC, SRY",
    "BUS IS LATE",
    "CAR BROKE DOWN",
    "BIKE HAD A FLAT",
    "HAD A WORK THING",
    "IT'S RAINING",
    "GOT HELD UP",
    "ON MY WAY",
    "COULDN'T FIND KEYS",
    "FORGOT MY WALLET",
    "FAMILY THING, SRY",
    "STOPPED TO PEE",
    "SPRAINED MY ANKLE",
    "CHATTY NEIGHBOR",
    "GOT LOST, SRY",
    "I'M HERE, WHERE ARE YOU",
    "GOT A FLAT TIRE",
    "GOT MUGGED",
    "DR APPT, SORRY",
    "TRAIN IS LATE",
    "THERE WAS CONSTRUCTION",
    "MISSED AN EXIT",
    "HAD BAD DIRECTIONS",
    "THE KIDS WERE FUSSY",
    "HAD TO WORK LATE",
    "FLIGHT WAS LATE",
    "STUCK BEHIND SLOW CAR",
    "HAD TO LET THE DOG OUT",
    "LONG LINE AT THE BANK",
    "HAD JURY DUTY",
    "HAD TO STOP FOR GAS",
    "GETTING A QUICK SNACK",
};

const bad_answers = [_][*c]const u8{
    "FORGOT MY CAT",
    "SHOE'S UNTIED",
    "ALIENS ??",
    "STUCK IN VORTEX",
    "IT'S RAINING MEN",
    "HAD TO DANCE",
    "PETTING A DOG",
    "HEAD STUCK IN WINDOW",
    "ICE CREAM TRUCK!",
    "STILL IN BED",
    "LEAVING SOON",
    "HULA HOOP CONTEST",
    "SRY, PILLOW FIGHT",
    "HAD TO SHAVE MY BACK",
    "FELL IN A HOLE",
    "STEPPED ON A CRACK",
    "WENT FOR A RUN",
    "COFFEE BREAK, SRY",
    "I'M TIRED"
};

const questions = [_][*c]const u8{
    "> Where are you?",
    "> Are you close?",
    "> What's taking so long?",
    "> Hello???",
    "> How much longer?",
    "> Is everything ok?",
    "> What are you doing?",
    "> Did something happen?",
    "> Any updates?",
    "> Need directions?",
    "> Are you still coming?",
    "> ETA?",
    "> Please hurry..",
    "> I'm getting worried..",
    "> Keep me posted",
    "> Any news?",
    "> All good?",
    "> Still on track?",
    "> Change of plans?",
    "> What's the status?",
    "> How's it looking?",
    "> Can you check in?",
    "> Update?",
    "> Need help?",
    "> More delays?",
    "> All clear?",
    "> Can you call?",
    "> Can I call?",
    "> On route?",
    "> Any change?",
    "> Any more issues?"
};

pub fn get_world_pos(p: ray.Vector3) ray.Vector3 {
    return ray.Vector3Add(p, world_origin);
}

pub fn inSlice(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |thing| {
        if (thing == needle) {
            return true;
        }
    }
    return false;
}

pub fn set_btns(bad_btn: *usize, prompt: *usize, btns: *[4]usize) void {
    bad_btn.* = @intCast(ray.GetRandomValue(0, 3));
    prompt.* = @intCast(ray.GetRandomValue(0, questions.len - 1));
    btns.* = .{
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1))
    };
    (btns.*)[bad_btn.*] = @intCast(ray.GetRandomValue(0, bad_answers.len - 1));
    for (0..2) |b| {
        while (inSlice(usize, btns.*[b+1..3], btns.*[b])){
            btns.*[b] = @intCast(ray.GetRandomValue(0, good_answers.len - 1));
        }
    }
}

var buf: [100]u8 = undefined;

pub fn main() !void {
    const SCREEN_W = 720;
    const SCREEN_H = 540;

    ray.InitWindow(SCREEN_W, SCREEN_H, "running late, sry");
    ray.InitAudioDevice();
    ray.SetMasterVolume(7);
    ray.SetTargetFPS(60);

    const target = ray.LoadRenderTexture(SCREEN_W / 2, SCREEN_H / 2);
    const wher_text = "> Where are you??";
    const late_text = "running late, sry <";
    const fsz = 20;
    const cam = ray.Camera3D{
        .position = get_world_pos(.{ .x = 0, .y = 0, .z = 10 }),
        .target = get_world_pos(.{ .x = 0, .y = 0, .z = 0 }),
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = ray.CAMERA_PERSPECTIVE,
    };

    var phone = ray.LoadModel("res/phone.glb");
    const fail_sound = ray.LoadSound("res/fail.wav");
    const succ_sound = ray.LoadSound("res/success.wav");
    const music = ray.LoadMusicStream("res/hit.mod");
    
    // set seed after load for some entropy
    ray.SetRandomSeed(@intFromFloat(ray.GetTime() * 219613));

    var day: u32 = 0;
    var score: f32 = 0.0;
    var time_started: f32 = 0.0;
    var time_excused: f32 = 5.0;
    var time_to_excuse: f32 = 5.0;
    var bad_btn: usize = @intCast(ray.GetRandomValue(0, 3));
    var prompt: usize = @intCast(ray.GetRandomValue(0, questions.len - 1));
    var btns: [4]usize = .{
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1)),
        @intCast(ray.GetRandomValue(0, good_answers.len - 1))
    };
    btns[bad_btn] = @intCast(ray.GetRandomValue(0, bad_answers.len - 1));
    for (0..2) |b| {
        while (inSlice(usize, btns[b+1..3], btns[b])){
            btns[b] = @intCast(ray.GetRandomValue(0, good_answers.len - 1));
        }
    }
    set_btns(&bad_btn, &prompt, &btns);

    while (!ray.WindowShouldClose()) {
        const time: f32 = @floatCast(ray.GetTime());
        const offset = .{ .x = @sin(time / 2) / 10, .y = @sin(time / 3) / 10, .z = @sin(time / 4) / 10 };
        const pos = get_world_pos(offset);
        // 3D in target_tex
        ray.BeginTextureMode(target);
        {
            ray.ClearBackground(ray.BLACK);
            ray.BeginMode3D(cam);
            {
                var mtx = ray.MatrixIdentity();
                const scl = ray.MatrixScale(3.85, 3.85, 3.85);
                const rot = ray.MatrixRotate(.{ .x = 0, .y = -1, .z = 0 }, ray.PI / 2);
                const rtx = ray.MatrixRotate(.{ .x = 0.93, .y = 0, .z = 0 }, @sin(time) * ray.PI / 100);
                const rty = ray.MatrixRotate(.{ .x = 0, .y = 0.51, .z = 0 }, @sin(time / 2) * ray.PI / 100);
                const rtz = ray.MatrixRotate(.{ .x = 0, .y = 0, .z = 0.23 }, @sin(time / 3) * ray.PI / 100);
                const trn = ray.MatrixTranslate(pos.x, pos.y, pos.z);
                mtx = ray.MatrixMultiply(mtx, scl);
                mtx = ray.MatrixMultiply(mtx, rot);
                mtx = ray.MatrixMultiply(mtx, rtx);
                mtx = ray.MatrixMultiply(mtx, rty);
                mtx = ray.MatrixMultiply(mtx, rtz);
                mtx = ray.MatrixMultiply(mtx, trn);

                phone.transform = mtx;
                var color = ray.BLUE;
                color.r /= 2;
                color.g /= 2;
                color.b /= 2;

                if(ray.IsSoundPlaying(succ_sound)){
                    color = ray.GREEN;
                    color.r /= 2;
                    color.g /= 2;
                    color.b /= 2;
                } else if (ray.IsSoundPlaying(fail_sound) or play_state == PlayState.Over){
                    color = ray.RED;
                    color.r /= 2;
                    color.g /= 2;
                    color.b /= 2;
                }
                ray.DrawModel(phone, .{}, 1, color);
            }
            ray.EndMode3D();
        }
        ray.EndTextureMode();

        // 2D
        ray.BeginDrawing();
        {
            ray.ClearBackground(ray.RAYWHITE);

            // blit 3D to screen
            ray.DrawTexturePro(target.texture, .{ .x = 0, .y = 0, .width = @floatFromInt(target.texture.width), .height = @floatFromInt(target.texture.height) }, .{ .x = 0, .y = 0, .width = SCREEN_W, .height = SCREEN_H }, .{ .x = 0, .y = 0 }, 0.0, ray.WHITE);

            const ox: i32 = @intFromFloat(offset.x * 50);
            const oy: i32 = @intFromFloat(offset.z * 50);


            switch (game_state) {
                GameState.Menu => {
                    // draw default texts
                    ray.DrawText(wher_text, SCREEN_W / 2 - 120 + ox, 75 + oy, fsz, ray.YELLOW);
                    const w = ray.MeasureText(wher_text, fsz);
                    ray.DrawText(late_text, SCREEN_W / 2 + 120 - w + ox, 105 + oy, fsz, ray.WHITE);

                    // start game
                    if (ray.GuiButton(.{ .x = SCREEN_W / 2 - 100, .y = SCREEN_H / 2.0 - 32, .width = 200, .height = 64 }, "START") == 1) {
                        day = 0;
                        score = 0.0;
                        time_started = 0.0;
                        time_excused = 5.0;
                        time_to_excuse = 5.0;
                        game_state = GameState.Play;
                    }
                },
                GameState.Play => {

                    switch (play_state){
                        PlayState.Init =>{
                            time_started = @floatCast(ray.GetTime());
                            play_state = PlayState.Play;
                            ray.SetMusicVolume(music, 3);
                            ray.PlayMusicStream(music);
                        },
                        PlayState.Play => {
                            ray.UpdateMusicStream(music);
                            time_excused -= ray.GetFrameTime();
                            if (time_excused < 0){
                                play_state = PlayState.Over;
                                ray.PlaySound(fail_sound);
                                ray.SetMusicVolume(music, 1.5);
                            }

                            const score_txt = try std.fmt.bufPrint(&buf, "{d:.01}", .{score});

                            ray.DrawText("SCORE:", 60, 40, fsz, ray.RAYWHITE);
                            ray.DrawText(score_txt.ptr, 60, 80, fsz, ray.RAYWHITE);

                            const time_txt = try std.fmt.bufPrint(&buf, "{d:.01}", .{time_excused});

                            ray.DrawText("TIME BOUGHT:", 60, 160, fsz, ray.RAYWHITE);
                            ray.DrawText(time_txt.ptr, 60, 200, fsz, ray.RAYWHITE);

                            ray.DrawText("EXCUSES:", 570, 40, fsz, ray.RAYWHITE);
                            ray.DrawText(questions[prompt], SCREEN_W / 2 - 120 + ox, 75 + oy, fsz, ray.YELLOW);

                            var btn_txt: [4]*const u8 = .{good_answers[btns[0]], good_answers[btns[1]], good_answers[btns[2]], good_answers[btns[3]]};
                            btn_txt[bad_btn] = bad_answers[btns[bad_btn] % (bad_answers.len - 1)];

                            if (ray.GuiButton(.{ .x = SCREEN_W * 3 / 4, .y = SCREEN_H / 6 * 1, .width = 160, .height = 64 }, btn_txt[0]) == 1) {
                                if(bad_btn == 0){
                                    fail(&score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(fail_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                } else {
                                    succ(&day, &score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(succ_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                }
                            }
                            if (ray.GuiButton(.{ .x = SCREEN_W * 3 / 4, .y = SCREEN_H / 6 * 2, .width = 160, .height = 64 }, btn_txt[1]) == 1) {
                                if(bad_btn == 1){
                                    fail(&score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(fail_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                } else {
                                    succ(&day, &score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(succ_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                }
                            }
                            if (ray.GuiButton(.{ .x = SCREEN_W * 3 / 4, .y = SCREEN_H / 6 * 3, .width = 160, .height = 64 }, btn_txt[2]) == 1) {
                                if(bad_btn == 2){
                                    fail(&score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(fail_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                } else {
                                    succ(&day, &score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(succ_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                }
                            }
                            if (ray.GuiButton(.{ .x = SCREEN_W * 3 / 4, .y = SCREEN_H / 6 * 4, .width = 160, .height = 64 }, btn_txt[3]) == 1) {
                                if(bad_btn == 3){
                                    fail(&score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(fail_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                } else {
                                    succ(&day, &score, &time_excused, &time_to_excuse);
                                    ray.PlaySound(succ_sound);
                                    set_btns(&bad_btn, &prompt, &btns);
                                }
                            }
                        },
                        PlayState.Over => {
                            ray.UpdateMusicStream(music);

                            const score_txt = try std.fmt.bufPrint(&buf, "{d:.01}", .{score});

                            ray.DrawText("SCORE:", 60, 40, fsz, ray.RAYWHITE);
                            ray.DrawText(score_txt.ptr, 60, 80, fsz, ray.RAYWHITE);

                            ray.DrawText("SCORE:", 60, 40, fsz, ray.RAYWHITE);
                            ray.DrawText(score_txt.ptr, 60, 80, fsz, ray.RAYWHITE);

                            ray.DrawText("> Forget it...", SCREEN_W / 2 - 120 + ox, 75 + oy, fsz, ray.YELLOW);

                            const w: f32 = @floatFromInt(ray.MeasureText("TOO LATE!!", 60));
                            ray.DrawTextPro(
                                ray.GetFontDefault(),
                                "TOO LATE!!",
                                .{ .x = SCREEN_W / 2 - w / 2, .y = SCREEN_H / 2.0 - w / 2},
                                .{},
                                30,
                                60,
                                10,
                                ray.RED,
                            );

                            if (ray.GuiButton(.{ .x = SCREEN_W / 2 - 100, .y = SCREEN_H * 3 / 4, .width = 200, .height = 64 }, "MENU") == 1) {
                                play_state = PlayState.Init;
                                game_state = GameState.Menu;
                                ray.StopMusicStream(music);
                            }
                        },
                    }
                },
            }
        }
        ray.EndDrawing();
    }

    ray.CloseWindow();
}

pub fn fail(score: *f32, time_excused: *f32, time_to_excuse: *f32) void {
    score.* -= time_to_excuse.* / 2;
    time_excused.* -= time_to_excuse.* / 2;
}

pub fn succ(day: *u32, score: *f32, time_excused: *f32, time_to_excuse: *f32) void {
    day.* += 1;
    if (day.* % 5 == 0)
        time_to_excuse.* *= 0.9;
    score.* += time_to_excuse.*;
    time_excused.* += time_to_excuse.*;
}