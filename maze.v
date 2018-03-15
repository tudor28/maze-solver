`timescale 1ns / 1ps

`define start           0
`define citeste_dreapta 1
`define citeste_inainte 2
`define verifica		   3
`define avanseaza       4
`define muta_dreapta    5
`define roteste_stanga  6
`define scrie           7
`define finish          8
`define asteapta		9

`define sus 				0
`define jos 				1
`define stanga 			2
`define dreapta 			3

module maze(
input clk,					// semnal de sincronizare
input [5:0] starting_col, starting_row, 	// coordonatele punctului de start pentru labirint
input  maze_in, 			// ofera informatii despre punctul de coordonate [row, col] - 0 daca e culoar, 1 daca e zid
output reg [5:0] row, col,	 // selecteaza un rând si o coloana din labirint
output reg maze_oe,			// output enable (activeaza citirea din labirint la rândul si coloana date) - semnal sincron	
output reg maze_we, 			// write enable (activeaza scrierea în labirint la rândul si coloana  date) - semnal sincron
output reg done);		 		// iesirea din labirint a fost gasita; semnalul ramane activ 
reg [5:0] current_row, current_col; 
reg [3:0] state=`start, next_state=`start;
reg [1:0] directie = `jos; //directia in care ma uit
reg [7:0] where; // indicator pentru ultima citire(daca s-a facut la dreapta sau inainte)
always @(posedge clk) begin
    state <= next_state;
end
 
always @(*) begin
	 maze_we=0;
    case (state)
	 `start: begin //blocul de initializare al automatului: se initializeaza pozitia curenta cu cea initiala în care ne aflam în labirint
		 current_row = starting_row;
		 current_col = starting_col;
		 done=0; //presupunem ca initial nu ne aflam la finalul labirintului
		 next_state=`scrie; //actualizarea labirintului cu coordonatele initiale
	 end
	 
    `citeste_dreapta: begin//citim o casuta la dreapta, fata de directia în care ne uitam
		 maze_oe=1; //pentru a putea citi din labirint
		 case(directie)//in functie de directia in care ma uit, casuta din dreapta difera
		 `jos: begin
			 row=current_row;
			 col=current_col-1;
			 end
		 `sus: begin
			 row=current_row;
			 col=current_col+1;
			 end
		 `dreapta: begin
			 row=current_row+1;
			 col=current_col;
			 end
		 `stanga: begin
			 row=current_row-1;
			 col=current_col;
			 end
		 endcase
	    where="d";//retinem ca ultima citire a fost o casuta din dreapta, pentru a putea sti ce verificare sa facem ulterior
		 next_state=`asteapta;//asteptam un clock pentru a termina citirea
	 end
	 
	 `citeste_inainte: begin
		 maze_oe=1; //pentru a putea citi din labirint
		 case(directie)//in functie de directia in care ma uit, casuta din fata difera
		 `jos: begin
			 row=current_row+1;
			 col=current_col;
			 end
		 `sus: begin
			 row=current_row-1;
			 col=current_col;
			 end
		 `dreapta: begin
			 row=current_row;
			 col=current_col+1;
			 end
		 `stanga: begin
			 row=current_row;
			 col=current_col-1;
			 end
		 endcase
		 where="i";//retinem ca ultima citire a fost o casuta din fata, pentru a putea sti ce verificare sa facem ulterior
		 next_state=`asteapta; //asteptam un clock pentru a termina citirea
	 end
	 
	  `asteapta: begin
		 maze_oe=0;
		 next_state=`verifica;//trecem in starea de verificare a casutei citite
	  end
	 
	 `verifica: begin
		 if(row==0 || row==63 || col==0 || col==63)//daca ne aflam la o pozitie distanta de marginea labirintului
			if(maze_in==0) begin//iar acesta este culoar
		 done=1;//am ajuns la finalul labirintului
		 maze_we=1;
		 current_col=col;
		 current_row=row;
				next_state=`finish;//intram in starea finala a labirintului
				end
			else
				next_state=`roteste_stanga;//altfel, ne rotim spre stanga, deoarece marginea fata de care suntem la o casuta distanta este perete
		 else
		 if(where=="d")//daca ultima casuta citita a fost din dreapta
			if(maze_in==0)//daca aceasta este culoar
				next_state=`muta_dreapta;//ne rotim spre dreapta si avansam o casuta
			else
				next_state=`citeste_inainte;//altfel, citim o casuta din fata
		 if(where=="i")//daca ultima casuta citita a fost din fata
			 if(maze_in==0)//daca aceasta este culoar
				next_state=`avanseaza;//avansam o pozitie
			 else
				next_state=`roteste_stanga;//altfel, ne rotim spre stanga
	 end
	 
	 `avanseaza: begin//avansam o casuta, in functie de directia spre care ne uitam
		case(directie)
		 `jos: current_row=current_row+1;
		 `sus: current_row=current_row-1;
		 `dreapta: current_col=current_col+1; 
		 `stanga: current_col=current_col-1;
		 endcase
		 next_state=`scrie;//actualizarea labirintului
	 end
	 
	 `muta_dreapta: begin//ne rotim spre dreapta si avansam o casuta, pentru a respecta din nou regula mainii drepte(sa avem perete in dreapta)
		case(directie)//in functie de directia spre care ne uitam, rotirea spre dreapta si avansarea difera
		 `jos: begin
			 directie=`stanga;
			 current_col=current_col-1;
			 end
		 `sus: begin
			 directie=`dreapta;
			 current_col=current_col+1;
			 end
		 `dreapta: begin
			 directie=`jos;
			 current_row=current_row+1;
			 end
		 `stanga: begin
			 directie=`sus;
			 current_row=current_row-1;
			 end
		 endcase
		 next_state=`scrie;
	 end
	 
	 `roteste_stanga: begin
		case(directie)//in functie de directia in care ne uitam, rotirea spre stanga difera
		`sus: directie=`stanga;
		`jos: directie=`dreapta;
		`stanga: directie=`jos;
		`dreapta: directie=`sus;
		endcase
		next_state=`citeste_dreapta;
	 end
	 
	 `scrie: begin //actualizare labirint
		 maze_we=1; //pentru a putea scrie in labirint
		 col=current_col;
		 row=current_row;
		 next_state=`citeste_dreapta; //se reia algoritmul cu o citire la dreapta, dupa regula
	 end
	 
		
	 `finish: begin//starea finala a automatului; automatul nu va mai iesi din aceasta stare dupa ce ajunge aici
	 end
	 
    endcase
end

endmodule
