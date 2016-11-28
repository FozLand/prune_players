nooption :
	rsync -a --exclude="*.sqlite" --exclude=".gitignore" --delete ~/.minetest/worlds/virtual/ ./test_data
 
install :
	cp ./mtio.lua ~/bin
	cp ./prune.lua ~/bin

.PHONY : test
test :
	rsync -a --exclude="*.sqlite" --exclude=".gitignore" --delete ~/.minetest/worlds/virtual/ ./test_data
