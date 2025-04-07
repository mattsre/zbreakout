const rl = @import("raylib");
const std = @import("std");

const lib = @import("breakout_core");

const Player = struct {
    model: rl.Rectangle,
    velocity: rl.Vector2,
    maxSpeed: f32,

    pub fn init() Player {
        const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());

        const playerWidth = 160;
        const playerHeight = 40;

        const playerModel = rl.Rectangle.init((screenWidth / 2) - (playerWidth / 2), screenHeight - 100, playerWidth, playerHeight);
        return Player{
            .model = playerModel,
            .velocity = rl.Vector2.init(0, 0),
            .maxSpeed = 10.0,
        };
    }

    pub fn draw(self: *Player) void {
        rl.drawRectangleRec(self.model, .black);
    }

    pub fn updateVelocity(self: *Player, v: rl.Vector2) void {
        const newVelocity = self.velocity.add(v);
        if (newVelocity.x >= 0 and newVelocity.x <= self.maxSpeed) {
            self.velocity.x = newVelocity.x;
        }

        if (newVelocity.x <= 0 and newVelocity.x >= -self.maxSpeed) {
            self.velocity.x = newVelocity.x;
        }
    }

    pub fn move(
        self: *Player,
    ) void {
        self.model.x += self.velocity.x;
        self.model.y += self.velocity.y;
    }
};

const Ball = struct {
    center: rl.Vector2,
    radius: f32,
    velocity: rl.Vector2,
    isReleased: bool,
    maxSpeed: f32,

    pub fn init() Ball {
        const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
        const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());

        return Ball{
            .center = rl.Vector2.init(screenWidth / 2, screenHeight - 150),
            .radius = 20,
            .isReleased = false,
            .velocity = rl.Vector2.init(0, 0),
            .maxSpeed = 20,
        };
    }

    pub fn draw(self: *Ball) void {
        rl.drawCircleV(self.center, self.radius, .black);
    }

    pub fn release(self: *Ball) void {
        if (self.isReleased == false) {
            self.velocity.y = -5.0;
            self.isReleased = true;
        }
    }

    pub fn move(
        self: *Ball,
    ) void {
        self.center = self.center.add(self.velocity);
    }

    pub fn invertYVelocity(self: *Ball) void {
        self.velocity.y *= -1;

        if (self.velocity.y >= 0 and self.velocity.y >= self.maxSpeed) {
            std.debug.print("setting max positive y velocity\n", .{});
            self.velocity.y = self.maxSpeed;
        }

        if (self.velocity.y <= 0 and self.velocity.y <= -self.maxSpeed) {
            std.debug.print("setting max negative y velocity\n", .{});
            self.velocity.y = -self.maxSpeed;
        }
    }

    pub fn invertXVelocity(self: *Ball) void {
        self.velocity.x *= -1;

        if (self.velocity.x >= 0 and self.velocity.x >= self.maxSpeed) {
            self.velocity.x = self.maxSpeed;
        }

        if (self.velocity.x <= 0 and self.velocity.x <= -self.maxSpeed) {
            self.velocity.x = -self.maxSpeed;
        }
    }
};

const WallLocation = enum {
    Top,
    Left,
    Bottom,
    Right,
};

const Wall = struct {
    location: WallLocation,
    model: rl.Rectangle,

    pub fn init(location: WallLocation, model: rl.Rectangle) Wall {
        return Wall{ .location = location, .model = model };
    }
};

const BreakableBlock = struct {
    model: rl.Rectangle,
    isBroken: bool,

    pub fn init(x: f32, y: f32) BreakableBlock {
        const blockModel = rl.Rectangle.init(x, y, 100, 50);
        return BreakableBlock{
            .model = blockModel,
            .isBroken = false,
        };
    }

    pub fn draw(self: BreakableBlock) void {
        if (self.isBroken == false) {
            rl.drawRectangleRec(self.model, .black);
        }
    }
};

pub fn generateBlockList(screenWidth: i32, allocator: std.mem.Allocator) !std.ArrayList(BreakableBlock) {
    var blocks = std.ArrayList(BreakableBlock).init(allocator);

    const screenEnd: f32 = @floatFromInt(screenWidth - 100);
    const blockMargin = 10;
    const start = rl.Vector2.init(45 - blockMargin, 50 - blockMargin);

    var position = start;
    for (0..3) |_| {
        while (position.x <= screenEnd) {
            const block = BreakableBlock.init(position.x, position.y);
            try blocks.append(block);
            position.x += block.model.width + blockMargin;
        }

        position.x = start.x;
        position.y += 50 + blockMargin;
    }

    return blocks;
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const screenWidth = 1600;
    const screenHeight = 900;

    rl.initWindow(screenWidth, screenHeight, "zig raylib breakout game");
    defer rl.closeWindow();

    var screenColliders = std.ArrayList(Wall).init(allocator);
    // top wall
    try screenColliders.append(Wall.init(WallLocation.Top, rl.Rectangle.init(0, 0, screenWidth, 1)));
    // left wall
    try screenColliders.append(Wall.init(WallLocation.Left, rl.Rectangle.init(0, 0, 1, screenHeight)));
    // bottom wall
    try screenColliders.append(Wall.init(WallLocation.Bottom, rl.Rectangle.init(0, screenHeight, screenWidth, 1)));
    // right wall
    try screenColliders.append(Wall.init(WallLocation.Right, rl.Rectangle.init(screenWidth, 0, 1, screenHeight)));

    const blocks = try generateBlockList(screenWidth, allocator);

    rl.setTargetFPS(60);

    var player = Player.init();
    var ball = Ball.init();
    var score: i32 = 0;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawText(rl.textFormat("Score: %i", .{score}), screenWidth - 150, screenHeight - 180, 24, .red);
        // rl.drawText("FPS: ", screenWidth - 150, screenHeight - 160, 20, .red);
        // rl.drawFPS(screenWidth - 100, screenHeight - 160);

        player.draw();
        ball.draw();

        for (blocks.items) |block| {
            block.draw();
        }

        const playerMovingLeft = if (rl.isKeyDown(rl.KeyboardKey.a) or rl.isKeyDown(rl.KeyboardKey.left)) true else false;
        const playerMovingRight = if (rl.isKeyDown(rl.KeyboardKey.d) or rl.isKeyDown(rl.KeyboardKey.right)) true else false;

        if (playerMovingLeft) {
            player.updateVelocity(rl.Vector2.init(-2, 0));
        }

        if (playerMovingRight) {
            player.updateVelocity(rl.Vector2.init(2, 0));
        }

        if (!playerMovingLeft and !playerMovingRight) {
            player.velocity.x = 0;
            player.velocity.y = 0;
        }

        if (rl.isKeyDown(rl.KeyboardKey.space)) {
            ball.release();
        }

        player.move();
        ball.move();

        for (screenColliders.items) |collider| {
            if (rl.checkCollisionRecs(player.model, collider.model)) {
                // std.debug.print("player has hit a collider \n", .{});
                if (collider.location == WallLocation.Left) {
                    player.model.x = collider.model.x + collider.model.width;
                } else {
                    player.model.x = collider.model.x - player.model.width;
                }
            }

            if (rl.checkCollisionCircleRec(ball.center, ball.radius, collider.model)) {
                if (collider.location == WallLocation.Bottom) {
                    // std.debug.print("ball hit bottom floor, game should end\n", .{});
                    ball.velocity = rl.Vector2.init(0, 0);
                } else if (collider.location == WallLocation.Left or collider.location == WallLocation.Right) {
                    ball.invertXVelocity();
                } else {
                    ball.invertYVelocity();
                }
            }
        }

        var blockInvertY = false;
        var blockInvertX = false;
        for (blocks.items) |*block| {
            if (block.isBroken) {
                continue;
            }

            if (rl.checkCollisionCircleRec(ball.center, ball.radius, block.model)) {
                block.isBroken = true;
                score += 10;

                // if ball is hitting on the side of a block
                if (ball.center.y >= block.model.y and ball.center.y <= block.model.y + block.model.height) {
                    blockInvertX = true;
                }

                blockInvertY = true;
            }
        }

        if (blockInvertY) {
            ball.invertYVelocity();
        }
        if (blockInvertX) {
            ball.invertXVelocity();
        }

        if (rl.checkCollisionCircleRec(ball.center, ball.radius, player.model)) {
            // if the ball is hitting the top of the paddle
            if (ball.center.y <= player.model.y) {
                ball.invertYVelocity();
                ball.velocity.x += player.velocity.x / 2;
            } else {
                std.debug.print("ball center: {}, paddle y: {}\n", .{ ball.center.y, player.model.y });
            }
        }
    }
}
