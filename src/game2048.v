module game2048;

    integer r;
    reg [7:0] ch;

    integer board[0:3][0:3];
    integer i, j;
    integer seed;
    integer score;

    // =======================================================
    // INITIAL
    // =======================================================
    initial begin
        seed = 32'h12345678;
        score = 0;

        // Delay so Python connects before first print
        #100_000;

        // clear board
        for (i=0;i<4;i=i+1)
            for (j=0;j<4;j=j+1)
                board[i][j] = 0;

        spawn_random_tile();
        spawn_random_tile();

        print_board_machine();
        $display("SCORE %0d", score);
        $fflush();
    end

    // =======================================================
    // INPUT LOOP
    // =======================================================
    initial begin : mainloop
    integer valid;

    // *** force input loop to start later ***
    #200_000;

    while (1) begin
        r = $fgetc(32'h8000_0000);

        if (r == -1) $finish;
        ch = r;
        valid = 0;

        case (ch)
            "w": begin move_up();    valid = 1; end
            "a": begin move_left();  valid = 1; end
            "s": begin move_down();  valid = 1; end
            "d": begin move_right(); valid = 1; end
            "q": begin
                    $display("QUIT");
                    $finish;
                end
        endcase

        if (valid == 1) begin
            seed = seed + 32'h1111;

            spawn_random_tile();

            print_board_machine();
            $display("SCORE %0d", score);

            if (check_win(0)) begin
                $display("WIN");
                $finish;
            end

            if (check_game_over(0)) begin
                $display("LOSE");
                $finish;
            end

            $fflush();
        end
    end
end

    // =======================================================
    // RANDOM TILE
    // =======================================================
    task spawn_random_tile;
        integer empty_y[0:15];
        integer empty_x[0:15];
        integer idx;
        integer count;
        integer tile;
        begin
            count = 0;
            for (i=0;i<4;i=i+1)
                for (j=0;j<4;j=j+1)
                    if (board[i][j] == 0) begin
                        empty_y[count] = i;
                        empty_x[count] = j;
                        count = count + 1;
                    end

            if (count != 0) begin
                idx = $random(seed) % count;
                if (idx < 0) idx = -idx;

                i = empty_y[idx];
                j = empty_x[idx];

                tile = 2;
                if (($random(seed) & 3) == 0) tile = 4;

                board[i][j] = tile;
            end
        end
    endtask

    // =======================================================
    // MOVE LOGIC
    // =======================================================
    task compress_left;
        integer y,x,k;
        begin
            for (y=0;y<4;y=y+1)
                for (x=0;x<4;x=x+1)
                    if (board[y][x]==0)
                        for(k=x+1;k<4;k=k+1)
                            if(board[y][k]!=0) begin
                                board[y][x] = board[y][k];
                                board[y][k] = 0;
                                k = 4;
                            end
        end
    endtask

    task merge_left;
        integer y,x;
        begin
            for (y=0;y<4;y=y+1)
                for (x=0;x<3;x=x+1)
                    if (board[y][x]!=0 && board[y][x]==board[y][x+1]) begin
                        board[y][x] = board[y][x] * 2;
                        score = score + board[y][x];
                        board[y][x+1] = 0;
                    end
        end
    endtask

    task move_left;
        begin
            compress_left();
            merge_left();
            compress_left();
        end
    endtask

    task move_right;
        begin
            mirror_h();
            move_left();
            mirror_h();
        end
    endtask

    task move_up;
        begin
            transpose();
            move_left();
            transpose();
        end
    endtask

    task move_down;
        begin
            transpose();
            move_right();
            transpose();
        end
    endtask

    task mirror_h;
        integer y,x,tmp;
        begin
            for(y=0;y<4;y=y+1)
                for(x=0;x<2;x=x+1) begin
                    tmp = board[y][x];
                    board[y][x] = board[y][3-x];
                    board[y][3-x] = tmp;
                end
        end
    endtask

    task transpose;
        integer y,x,tmp;
        begin
            for(y=0;y<4;y=y+1)
                for(x=y+1;x<4;x=x+1) begin
                    tmp = board[y][x];
                    board[y][x] = board[x][y];
                    board[x][y] = tmp;
                end
        end
    endtask

    // =======================================================
    // WIN / LOSE CHECKS
    // =======================================================
    function integer check_win;
        input dummy;
        integer y,x;
        begin
            check_win = 0;
            for(y=0;y<4;y=y+1)
                for(x=0;x<4;x=x+1)
                    if(board[y][x] == 2048)
                        check_win = 1;
        end
    endfunction

    function integer check_game_over;
        input dummy;
        integer y,x;
        integer full;
        begin
            full = 1;

            for(y=0;y<4;y=y+1)
                for(x=0;x<4;x=x+1)
                    if(board[y][x] == 0)
                        full = 0;

            for(y=0;y<4;y=y+1)
                for(x=0;x<4;x=x+1) begin
                    if (y<3 && board[y][x]==board[y+1][x]) full = 0;
                    if (x<3 && board[y][x]==board[y][x+1]) full = 0;
                end

            check_game_over = full;
        end
    endfunction

    // =======================================================
    // MACHINE READABLE OUTPUT
    // =======================================================
    task print_board_machine;
        integer y,x;
        begin
            $write("BOARD");
            for (y=0;y<4;y=y+1)
                for (x=0;x<4;x=x+1)
                    $write(" %0d", board[y][x]);
            $display("");
        end
    endtask

endmodule