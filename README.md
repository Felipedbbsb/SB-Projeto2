Projeto de Software Básico (SB) da Universidade de Brasília (UnB), o qual tem como objetivo simular um carregador de arquivos.

Autores: Belphy Pierre Starling (202006420) e Felipe Dantas Borges

Para compilar, basta digitar `make`.

Após isso, para rodar, digite o comando `./carregador` seguido pelos parâmetros.

O primeiro parâmetro é necessário e constitui o tamanho de memória que o programa a ser carregado possui.

Os seguintes parâmetros determinam um bloco de memória disponível, sendo passados em pares nos parâmetros,
o primeiro elemento do par é o endereço inicial do bloco e o segundo elemento é o tamanho do bloco.
É aceito passar até 4 blocos como parâmetro.

O output do programa irá informar se o programa a ser carregador cabe na memória ou não,
e se cabe, em qual bloco será armazenado e seu respectivo endereço inicial e final.

O carregador priorizará armazenar o programa em um só bloco, caso não for possível,
irá fracionar e colocar nos blocos disponíveis seguido a ordem passada pelos parâmetros.

Exemplo de uso:
`./carregador 100 100 50 200 100`

O programa possui 100 de tamanho.
O primeiro bloco tem como endereço inicial 100 e 50 de tamanho, ou seja, endereco final 149.
O segundo bloco, começa em 200 e tem 100 de tamanho, terminando em 299.
Logo, o programa será armazenado no segundo bloco e irá informar que está armazenado no endereço 200 até 299.

Observação:

Caso tenha problema ligando o programa, instale o pacote gcc de 32 bits (gcc-multilib)
