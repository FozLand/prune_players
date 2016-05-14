nooption :
	rsync -a --exclude="*.sqlite" --exclude=".gitignore" --delete ~/.minetest/worlds/virtual/ ./test_data
 
.PHONY : test
test :
	rsync -a --exclude="*.sqlite" --exclude=".gitignore" --delete ~/.minetest/worlds/virtual/ ./test_data
