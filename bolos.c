#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <sys/time.h>

pid_t v_pid[5];
char nombre[10];
pid_t pid;
int hijosMuertos = 0;

int crearHijo(char *nombre)
{
	pid_t pid;
	char cadenaH[10];
	char cadenaE[10];
	char cadenaI[10];

	pid = fork();
	switch (pid)
	{
	case -1:
		perror("ERROR EN FORK");
		return 1;
		break;

	case 0: // Hijo nuevo

		sprintf(cadenaH, "%i", v_pid[0]);
		sprintf(cadenaE, "%i", v_pid[1]);
		sprintf(cadenaI, "%i", v_pid[2]);
		if(execl("./bolos", nombre, cadenaH, cadenaE, cadenaI, NULL)==-1) perror("ERROR EN EXECL");
		break;

	default: // Padre
		break;
	}

	return pid;
}

//pasa por parametro el pid por el que quiere esperar, cambiar a waitpid
void esperarPadre(pid_t espera){

	int valor_devuelto;

	if(waitpid(espera, &valor_devuelto, 0) == -1) perror("ERROR EN WAIT");
	hijosMuertos += WEXITSTATUS(valor_devuelto);
}

void matarHijos()
{
	struct timeval tiempo;
	if(gettimeofday(&tiempo, NULL)==-1) perror("ERROR EN GETTIMEOFDAY");

	if(strcmp(nombre,"A")==0){

		int valor_devuelto;

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre); printf("A no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre); printf("A mata a C\n"); if(kill(v_pid[4], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(v_pid[4]); break; //mata C
			case 2: printf("DENTRO SWITCH %s\n", nombre); printf("A mata a B\n"); if(kill(v_pid[3], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(v_pid[3]); break; //mata B
			case 3: printf("DENTRO SWITCH %s\n", nombre); printf("A mata a B y C\n"); if(kill(v_pid[3], SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[4], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(v_pid[3]); esperarPadre(v_pid[4]); break;
		}

		if(waitpid(v_pid[0], &valor_devuelto, WNOHANG) == -1) perror("ERROR EN WAIT");
		if(WIFEXITED(valor_devuelto)) hijosMuertos += WEXITSTATUS(valor_devuelto);
		if(waitpid(v_pid[1], &valor_devuelto, WNOHANG) == -1) perror("ERROR EN WAIT");
		if(WIFEXITED(valor_devuelto)) hijosMuertos += WEXITSTATUS(valor_devuelto);
		if(waitpid(v_pid[2], &valor_devuelto, WNOHANG) == -1) perror("ERROR EN WAIT");
		if(WIFEXITED(valor_devuelto)) hijosMuertos += WEXITSTATUS(valor_devuelto);


	}else if(strcmp(nombre,"B")==0){

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre); printf("B no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre); printf("B mata a E\n"); if(kill(v_pid[1], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata E
			case 2: printf("DENTRO SWITCH %s\n", nombre); printf("B mata a D\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break; //mata D
			case 3: printf("DENTRO SWITCH %s\n", nombre); printf("B mata a D y E\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[1], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break;
		}

	}else if(strcmp(nombre,"C")==0){

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre); printf("C no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre); printf("C mata a F\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break; //mata F
			case 2: printf("DENTRO SWITCH %s\n", nombre); printf("C mata a E\n"); if(kill(v_pid[1], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata E
			case 3: printf("DENTRO SWITCH %s\n", nombre); printf("C mata a F y E\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[1], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break;
		}

	}else if(strcmp(nombre,"D")==0){

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre);printf("D no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre);printf("D mata a H\n"); if(kill(v_pid[0], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata H
			case 2: printf("DENTRO SWITCH %s\n", nombre);printf("D mata a G\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break; //mata G
			case 3: printf("DENTRO SWITCH %s\n", nombre);printf("D mata a G y H\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[0], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break;
		}

	}else if(strcmp(nombre,"F")==0){

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre);printf("F no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre);printf("F mata a I\n"); if(kill(v_pid[2], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata I
			case 2: printf("DENTRO SWITCH %s\n", nombre);printf("F mata a J\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid); break; //mata J
			case 3: printf("DENTRO SWITCH %s\n", nombre);printf("F mata a I y J\n"); if(kill(pid, SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[2], SIGTERM)==-1) perror("ERROR EN KILL"); esperarPadre(pid);break;
		}

	}else if(strcmp(nombre,"E")==0){

		int matar = tiempo.tv_usec%4;

		printf("ANTES SWITCH %s\n", nombre);

		switch (matar)
		{
			case 0: printf("DENTRO SWITCH %s\n", nombre);printf("E no mata a nadie\n"); break;
			case 1: printf("DENTRO SWITCH %s\n", nombre);printf("E mata a I\n"); if(kill(v_pid[2], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata I
			case 2: printf("DENTRO SWITCH %s\n", nombre);printf("E mata a H\n"); if(kill(v_pid[0], SIGTERM)==-1) perror("ERROR EN KILL"); break; //mata H
			case 3: printf("DENTRO SWITCH %s\n", nombre);printf("E mata a I y H\n"); if(kill(v_pid[2], SIGTERM)==-1) perror("ERROR EN KILL"); if(kill(v_pid[0], SIGTERM)==-1) perror("ERROR EN KILL"); break;
		}
	}
}

int main(int argc, char *argv[])
{
	sigset_t maskTodas;
	sigfillset(&maskTodas);
	if(sigprocmask(SIG_SETMASK, &maskTodas, NULL)==-1) perror("ERROR EN SIGPROCMASK");

	sigset_t maskSigTerm;
	sigfillset(&maskSigTerm);
	sigdelset(&maskSigTerm, SIGTERM);

	struct sigaction nuevo;
	nuevo.sa_handler = &matarHijos;
	nuevo.sa_flags = SA_RESTART;
	nuevo.sa_mask = maskTodas;
	if(sigaction(SIGTERM, &nuevo, NULL)==-1) perror("ERROR EN SIGACTION");

	strcpy(nombre, argv[0]);

	if(strcmp(argv[0], "./bolos") != 0 && strcmp(argv[0], "bolos") != 0 ){
		v_pid[0]=atoi(argv[1]);
		v_pid[1]=atoi(argv[2]);
		v_pid[2]=atoi(argv[3]);
	}

	if (strcmp(argv[0], "./bolos") == 0 || strcmp(argv[0], "bolos") == 0)
	{
		crearHijo("A");
	}
	else if (strcmp(argv[0], "A") == 0)
	{
		v_pid[0] = crearHijo("H");
		v_pid[1] = crearHijo("E");
		v_pid[2] = crearHijo("I");
		v_pid[3] = crearHijo("B");
		v_pid[4] = crearHijo("C");


		printf("Escribe kill %i para tirar la bola.\n", getpid());
		sigsuspend(&maskSigTerm);
		sleep(2);

		printf("HIJOS MUERTOS %i\n", hijosMuertos);

		system("ps");
	}
	else if (strcmp(argv[0], "B") == 0)
	{
		pid = crearHijo("D");
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "D") == 0)
	{
		pid = crearHijo("G");
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "G") == 0)
	{	
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "C") == 0)
	{
		pid = crearHijo("F");
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "F") == 0)
	{
		pid = crearHijo("J");
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "J") == 0)
	{
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "H") == 0)
	{
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "E") == 0)
	{
		sigsuspend(&maskSigTerm);
	}
	else if (strcmp(argv[0], "I") == 0)
	{
		sigsuspend(&maskSigTerm);
	}

	return 1+hijosMuertos;
}
