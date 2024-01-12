const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub fn main() void {
    const SCREEN_W = 720;
    const SCREEN_H = 540;

    ray.InitWindow(SCREEN_W, SCREEN_H, "zrayjam");
    ray.SetTargetFPS(60);

    var target = ray.LoadRenderTexture(SCREEN_W / 4, SCREEN_H / 4);

    const txt = "Zello, Rayworld!";
    const fsz = 30;

    var cam = ray.Camera3D{
        .position = .{ .x = 10, .y = 10, .z = 10 },
        .target = .{ .x = 5, .y = 5, .z = 5 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = ray.CAMERA_PERSPECTIVE,
    };
    var cube_msh = ray.GenMeshCube(1, 1, 1);
    var mod = ray.LoadModelFromMesh(cube_msh);
    _ = mod;

    var phone = ray.LoadModel("res/phone.glb");

    while (!ray.WindowShouldClose()) {
        if (ray.IsKeyDown(ray.KEY_W)) {
            cam.position.y += 1 * ray.GetFrameTime();
            cam.target.y += 1 * ray.GetFrameTime();
        }
        if (ray.IsKeyDown(ray.KEY_S)) {
            cam.position.y -= 1 * ray.GetFrameTime();
            cam.target.y -= 1 * ray.GetFrameTime();
        }
        if (ray.IsKeyDown(ray.KEY_A)) {
            cam.position.z -= 1 * ray.GetFrameTime();
            cam.target.z -= 1 * ray.GetFrameTime();
        }
        if (ray.IsKeyDown(ray.KEY_D)) {
            cam.position.z += 1 * ray.GetFrameTime();
            cam.target.z += 1 * ray.GetFrameTime();
        }

        // 3D in target_tex
        ray.BeginTextureMode(target);
        {
            ray.ClearBackground(ray.BLACK);
            ray.BeginMode3D(cam);
            {
                var time: f32 = @floatCast(ray.GetTime());
                var mtx = ray.MatrixIdentity();
                // var rot = ray.MatrixRotate(.{ .x = 0.97, .y = 0.53, .z = 0.23 }, time);
                var trn = ray.MatrixTranslate(5 + @sin(time / 2), 5 + @sin(time / 3), 5 + @sin(time / 4));
                // mtx = ray.MatrixMultiply(mtx, rot);
                mtx = ray.MatrixMultiply(mtx, trn);

                phone.transform = mtx;
                ray.DrawModel(phone, .{}, 1, ray.RED);

                ray.DrawGrid(10, 10);
                // mod.transform = mtx;
                // ray.DrawModel(mod, .{}, 1, ray.GREEN);
                // ray.DrawModelWires(mod, .{}, 1, ray.DARKGREEN);
            }
            ray.EndMode3D();
        }
        ray.EndTextureMode();

        // 2D
        ray.BeginDrawing();
        {
            ray.ClearBackground(ray.RAYWHITE);

            // blit 3D to screen
            ray.DrawTexturePro(target.texture, .{ .x = 0, .y = 0, .width = SCREEN_W / 4, .height = SCREEN_H / 4 }, .{ .x = 0, .y = 0, .width = SCREEN_W, .height = SCREEN_H }, .{ .x = 0, .y = 0 }, 0.0, ray.WHITE);

            var w = ray.MeasureText(txt, fsz);
            ray.DrawText(txt, SCREEN_W / 2 - @divTrunc(w, 2), 100, fsz, ray.GRAY);

            ray.DrawFPS(10, 10);
        }
        ray.EndDrawing();
    }

    ray.CloseWindow();
}
