package proscenium_test

import (
	. "joelmoss/proscenium/test/support"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Build(css)", func() {
	Describe("plain css", func() {
		It("should build", func() {
			Expect(Build("lib/foo.css")).To(ContainCode(`.body { color: red; }`))
		})
	})

	Describe("css module", func() {
		path := "app/components/phlex/side_load_css_module_view.module.css"

		It("should build", func() {
			Expect(Build(path)).To(ContainCode(`.basebd9b41e5 { color: red; }`))
		})
	})

	When("importing absolute path", func() {
		It("should bundle", func() {
			Expect(Build("lib/import_absolute.css")).To(ContainCode(`.stuff { color: red; }`))
		})
	})

	When("importing css module from css", func() {
		It("should bundle", func() {
			Expect(Build("lib/css_modules/import_css_module.css")).To(ContainCode(`
					/* lib/css_modules/basic.module.css */
          .fooc3f452b4 { color: red; }
          /* lib/css_modules/import_css_module.css */
          .bar { color: blue; }
				`))
		})
	})

	When("importing css module from css module", func() {
		It("should bundle with same digest", func() {
			result := Build("lib/css_modules/import_css_module.module.css")

			Expect(result).To(ContainCode(`.foo60bd820c { color: red; }`))
			Expect(result).To(ContainCode(`.bar60bd820c { color: blue; }`))
		})
	})

	When("importing relative path", func() {
		It("should bundle", func() {
			Expect(Build("lib/import_relative.css")).To(ContainCode(`
					/* lib/foo.css */
					.body { color: red; }
					/* lib/foo2.css */
					.body { color: blue; }
				`))
		})
	})

	When("importing bare specifier", func() {
		It("is replaced with absolute path", func() {
			result := Build("lib/import_npm_module.css")

			Expect(result).To(ContainCode(`[hidden] { display: none; }`))
			Expect(result).NotTo(ContainCode(`@import 'normalize.css';`))
			Expect(result).NotTo(ContainCode(`
					@import "/node_modules/.pnpm/normalize.css@8.0.1/node_modules/normalize.css/normalize.css";
				`))
		})
	})

	Describe("mixins", func() {
		When("from URL", func() {
			It("is replaced with defined mixin", func() {
				Expect(Build("lib/with_mixin_from_url.css")).To(ContainCode(`
						a { color: red; font-size: 20px; }
					`))
			})
		})

		When("from relative URL", func() {
			It("is replaced with defined mixin", func() {
				Expect(Build("lib/with_mixin_from_relative_url.css")).To(ContainCode(`
					a { color: red; font-size: 20px; }
				`))
			})
		})
	})

	When("importing css module from js", func() {
		var expectedCode = `
			var existingStyle = document.querySelector("#_330940eb");
			var existingLink = document.querySelector('link[href="/lib/styles.module.css"]');
			if (!existingStyle && !existingLink) {
				const e = document.createElement("style");
				e.id = "_330940eb";
				e.dataset.href = "/lib/styles.module.css";
				e.appendChild(document.createTextNode(` + "`/* lib/styles.module.css */" + `
			.myClass330940eb {
        color: pink;
      }` + "`" + `));
				document.head.insertBefore(e, document.querySelector("style"));
			}
			var styles_module_default = new Proxy({}, {
				get(target, prop, receiver) {
					if (prop in target || typeof prop === "symbol") {
						return Reflect.get(target, prop, receiver);
					} else {
						return prop + "330940eb";
					}
				}
			});
		`

		It("includes stylesheet and proxies class names", func() {
			Expect(Build("lib/import_css_module.js")).To(ContainCode(expectedCode))
		})

		It("import relative css module from js", func() {
			Expect(Build("lib/import_relative_css_module.js")).To(ContainCode(expectedCode))
		})

		When("importing css module from css module", func() {
			path := "lib/css_modules/import_css_module.js"

			It("should bundle with same digest", func() {
				result := Build(path)

				Expect(result).To(ContainCode(`.foo60bd820c { color: red; }`))
				Expect(result).To(ContainCode(`.bar60bd820c { color: blue; }`))
			})
		})
	})
})
