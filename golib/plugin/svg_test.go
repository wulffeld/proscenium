package plugin_test

import (
	"joelmoss/proscenium/golib/plugin"
	"os"
	"path"
	"testing"

	"github.com/evanw/esbuild/pkg/api"
	"github.com/gkampitakis/go-snaps/snaps"
)

func TestMain(t *testing.M) {
	v := t.Run()
	snaps.Clean(t)
	os.Exit(v)
}

func TestSvgPlugin(t *testing.T) {
	var cwd, _ = os.Getwd()
	var root string = path.Join(cwd, "../../", "test", "fixtures", "svg_plugin")
	t.Run("local import in jsx", func(t *testing.T) {
		result := api.Build(api.BuildOptions{
			EntryPoints:   []string{"local.jsx"},
			External:      []string{"react"},
			AbsWorkingDir: root,
			Format:        api.FormatESModule,
			JSX:           api.JSXPreserve,
			Bundle:        true,
			Write:         false,
			Plugins:       []api.Plugin{plugin.Svg},
		})

		snaps.MatchSnapshot(t, string(result.OutputFiles[0].Contents))
	})

	t.Run("remote import in jsx", func(t *testing.T) {
		t.Skip("TODO")

		result := api.Build(api.BuildOptions{
			EntryPoints:   []string{"remote.jsx"},
			External:      []string{"react"},
			AbsWorkingDir: root,
			Format:        api.FormatESModule,
			JSX:           api.JSXPreserve,
			Bundle:        true,
			Write:         false,
			Plugins:       []api.Plugin{plugin.Svg},
		})

		snaps.MatchSnapshot(t, string(result.OutputFiles[0].Contents))
	})
}
