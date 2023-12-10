package main

import (
 "github.com/gofiber/fiber/v2"
 "github.com/gofiber/fiber/v2/middleware/logger"
 "github.com/gofiber/template/html"

 "fmt"
 "os/exec"
)

func main() {
 // Initialize standard Go html template engine
 engine := html.New("./views", ".html")

 app := fiber.New(fiber.Config{
  Views: engine,
 })
 app.Use(logger.New())

 app.Get("/", func(c *fiber.Ctx) error {
  type Request struct {
   Hostname string `query:"hostname"`
  }
  r := new(Request)

  if err := c.QueryParser(r); err != nil {
   return c.SendStatus(fiber.StatusBadRequest)
  }

  if r.Hostname == "" {
   return c.Render("index", fiber.Map{
    "hostname": r.Hostname,
    "output":   "",
   })
  }

  cmdString := fmt.Sprintf("ping -c 2 %s", r.Hostname)

  cmd := exec.Command("bash", "-c", cmdString)
  stdoutStderr, err := cmd.CombinedOutput()
  if err != nil {
   return c.Render("index", fiber.Map{
    "hostname": r.Hostname,
    "output":   err,
   })
  }
  return c.Render("index", fiber.Map{
   "hostname": r.Hostname,
   "output":   string(stdoutStderr),
  })
 })

 err := app.Listen(":3000")
 if err != nil {
  panic(err)
 }
}