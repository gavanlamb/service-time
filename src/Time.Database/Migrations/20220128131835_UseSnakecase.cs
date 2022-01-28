using Microsoft.EntityFrameworkCore.Migrations;

namespace Time.Database.Migrations
{
    public partial class UseSnakecase : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_Records",
                table: "Records");

            migrationBuilder.RenameTable(
                name: "Records",
                newName: "records");

            migrationBuilder.RenameColumn(
                name: "Start",
                table: "records",
                newName: "start");

            migrationBuilder.RenameColumn(
                name: "Name",
                table: "records",
                newName: "name");

            migrationBuilder.RenameColumn(
                name: "Modified",
                table: "records",
                newName: "modified");

            migrationBuilder.RenameColumn(
                name: "End",
                table: "records",
                newName: "end");

            migrationBuilder.RenameColumn(
                name: "Duration",
                table: "records",
                newName: "duration");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "records",
                newName: "created");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "records",
                newName: "id");

            migrationBuilder.RenameColumn(
                name: "UserId",
                table: "records",
                newName: "user_id");

            migrationBuilder.RenameIndex(
                name: "IX_Records_UserId",
                table: "records",
                newName: "ix_records_user_id");

            migrationBuilder.AddPrimaryKey(
                name: "pk_records",
                table: "records",
                column: "id");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "pk_records",
                table: "records");

            migrationBuilder.RenameTable(
                name: "records",
                newName: "Records");

            migrationBuilder.RenameColumn(
                name: "start",
                table: "Records",
                newName: "Start");

            migrationBuilder.RenameColumn(
                name: "name",
                table: "Records",
                newName: "Name");

            migrationBuilder.RenameColumn(
                name: "modified",
                table: "Records",
                newName: "Modified");

            migrationBuilder.RenameColumn(
                name: "end",
                table: "Records",
                newName: "End");

            migrationBuilder.RenameColumn(
                name: "duration",
                table: "Records",
                newName: "Duration");

            migrationBuilder.RenameColumn(
                name: "created",
                table: "Records",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "id",
                table: "Records",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "user_id",
                table: "Records",
                newName: "UserId");

            migrationBuilder.RenameIndex(
                name: "ix_records_user_id",
                table: "Records",
                newName: "IX_Records_UserId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Records",
                table: "Records",
                column: "Id");
        }
    }
}
